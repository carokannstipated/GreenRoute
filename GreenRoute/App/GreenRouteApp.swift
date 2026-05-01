// Entry point for the GreenRoute app. Wires the SwiftUI lifecycle to UIKit's AppDelegate
// for background task registration, background fetch handling, and notification delegation.

import SwiftUI
import BackgroundTasks
import GreenRouteDomain
import GreenRouteData
import GreenRouteService

/// SwiftUI App entry point. Delegates app-lifecycle concerns to AppDelegate via the adaptor.
@main
struct GreenRouteApp: App {

    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            AppCompositionRoot(service: appDelegate.service)
        }
    }
}

/// UIApplicationDelegate responsible for:
/// - Registering and scheduling background refresh tasks.
/// - Running the inactivity check when the app is refreshed in the background
/// - Handling foreground notification presentation (banner and sound)
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    /// Shared service instance for the app lifetime. Marked nonisolated(unsafe) to allow access from concurrent contexts.
    /// Treated as immutable after initialization.

    nonisolated(unsafe) let service: any GreenRouteService = GreenRouteServiceFactory.make()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        registerBackgroundTask()
        scheduleBackgroundFetch()
        return true
    }

    /// Handles background fetch by running the inactivity check and scheduling a recommendation if needed.
    func application(
        _ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        let service = service
        let checker = service.inactivityChecker

        Task {
            let didScheduleRecommendation = await BackgroundFetchHandler.run(
                service: service,
                checker: checker
            )
            completionHandler(didScheduleRecommendation ? .newData : .noData)
        }
    }

    /// Allows notification banners and sounds to appear even when the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// Registers the BGTaskScheduler handler for the inactivity background task identifier.
    /// Runs the inactivity check flow, handles expiration, and completes the task
    private func registerBackgroundTask() {
        let checker = service.inactivityChecker
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.greenroute.inactivity",
            using: nil
        ) { task in
            Task { @MainActor [checker] in
                let service = self.service
                let work = Task.detached { await BackgroundFetchHandler.run(service: service, checker: checker) }
                task.expirationHandler = { work.cancel() }
                _ = await work.result
                task.setTaskCompleted(success: !work.isCancelled)
            }
        }
    }

    /// Submits a BGAppRefreshTaskRequest to fire no earlier than 15 minutes from now
    /// Called at launch and re-scheduled at the end of every background run.
    private func scheduleBackgroundFetch() {
        let request = BGAppRefreshTaskRequest(identifier: "com.greenroute.inactivity")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
}

/// Stateless namespace for the logic executed during both legacy background fetch
/// and the modern BGTask background refresh.
private enum BackgroundFetchHandler {

    /// Checks for inactivity, detects recurring break patterns, and schedules a green break
    /// notification if conditions are met. Re-schedules the next background fetch before returning.
    /// - Returns: true if a notification was scheduled during this run.
    static func run(service: any GreenRouteService, checker: any InactivityChecking) async -> Bool {
        let now = Date()
        let inactivity = await checker.checkInactivity()
        var didScheduleRecommendation = false

        do {
            let modelContainer = try ModelContainerFactory.makePersistentContainer()
            let inactivityRepo = SwiftDataInactivityEventRepository(container: modelContainer)
            let locationVisitRepo = SwiftDataLocationVisitRepository(container: modelContainer)
            let recommendationRepo = SwiftDataRecommendationRepository(container: modelContainer)
            let patternRepo = SwiftDataRecurringPatternRepository(container: modelContainer)

            if let inactivity {
                try await inactivityRepo.save(inactivity)
            }

            let useCase = DetectRecurringPatternUseCase(
                inactivityRepository: inactivityRepo,
                patternRepository: patternRepo
            )
            let detectedPattern = try await useCase.execute(now: now, calendar: Calendar.current)
            let latestPattern = try await patternRepo.fetchLatest()
            // Use the freshly detected pattern if available; fall back to the last stored one.
            let activePattern = detectedPattern ?? latestPattern

            let trigger = recommendationTrigger(
                inactivity: inactivity,
                pattern: activePattern,
                now: now,
                calendar: Calendar.current
            )

            if let trigger,
               let coordinate = try await latestCoordinate(repository: locationVisitRepo, now: now) {
                let settings = UserDefaultsSettingsRepository().load()
                let recommendationsToday = try await recommendationsForToday(
                    repository: recommendationRepo,
                    now: now,
                    calendar: Calendar.current
                )
                let recommendationUseCase = GenerateGreenBreakUseCase(
                    greenAreaProvider: service.greenAreaProvider,
                    recommendationEngine: RecommendationEngine(),
                    recommendationRepository: recommendationRepo,
                    notificationPolicy: NotificationPolicy(maxPerDay: 2, minimumInterval: 4 * 60 * 60),
                    notificationScheduler: service.notificationScheduler
                )
                let inactivityThresholdMinutes = 2
                // If no inactivity event was detected, synthesise one using the threshold window
                // so the recommendation use case has a valid event to work with.
                let event = inactivity ?? InactivityEvent(
                    start: now.addingTimeInterval(-TimeInterval(inactivityThresholdMinutes * 60)),
                    end: now
                )

                let output = try await recommendationUseCase.execute(
                    inactivity: event,
                    currentCoordinate: coordinate,
                    inactivityThresholdMinutes: inactivityThresholdMinutes,
                    maxDistance: maxDistance(from: settings),
                    searchRadius: DistanceMeters(value: 500),
                    sentCountToday: recommendationsToday.count,
                    lastNotificationSentAt: recommendationsToday.first?.createdAt,
                    shouldScheduleNotification: true,
                    now: now,
                    trigger: trigger
                )
                didScheduleRecommendation = output.didScheduleNotification
            }
        } catch {}

        // Always schedules the next background refresh before returning
        let request = BGAppRefreshTaskRequest(identifier: "com.greenroute.inactivity")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
        return didScheduleRecommendation
    }

    /// Determines what triggered the recommendation opportunity: detected inactivity takes precedence
    /// over a recurring time-of-day pattern.
    private static func recommendationTrigger(
        inactivity: InactivityEvent?,
        pattern: RecurringPattern?,
        now: Date,
        calendar: Calendar
    ) -> Recommendation.Trigger? {
        if inactivity != nil { return .inactivity }

        guard let pattern else { return nil }
        let components = calendar.dateComponents([.hour, .minute], from: now)
        let minutesFromMidnight = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        return pattern.window.contains(minutesFromMidnight: minutesFromMidnight) ? .pattern : nil
    }

    /// Fetches the most recent location visit within the last 7 days.
    /// Returns nil if no visits are recorded, which prevents recommendations without a valid position.
    private static func latestCoordinate(
        repository: any LocationVisitRepository,
        now: Date
    ) async throws -> Coordinate? {
        let visits = try await repository.fetch(
            from: now.addingTimeInterval(-7 * 24 * 60 * 60),
            to: now.addingTimeInterval(60)
        )
        return visits.first?.coordinate
    }

    /// Fetches all recommendations created today (midnight to midnight) to enforce the daily cap.
    private static func recommendationsForToday(
        repository: any RecommendationRepository,
        now: Date,
        calendar: Calendar
    ) async throws -> [Recommendation] {
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
        return try await repository.fetch(from: start, to: end)
    }

    /// Converts the user's max route duration setting into a walking distance limit.
    /// Assumes 1.4 m/s walking speed over the outbound half of the trip.
    private static func maxDistance(from settings: AppSettings) -> DistanceMeters {
        DistanceMeters(value: Double(settings.maxRouteDurationMinutes) * 60.0 * 1.4 / 2.0)
    }
}
