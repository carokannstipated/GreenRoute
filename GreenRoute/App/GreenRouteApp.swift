//
//  GreenRouteApp.swift
//  GreenRoute
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//

import SwiftUI
import BackgroundTasks
import GreenRouteDomain
import GreenRouteData
import GreenRouteService

@main
struct GreenRouteApp: App {

    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            AppCompositionRoot(service: appDelegate.service)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

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

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

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

    private func scheduleBackgroundFetch() {
        let request = BGAppRefreshTaskRequest(identifier: "com.greenroute.inactivity")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
}

private enum BackgroundFetchHandler {
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

        let request = BGAppRefreshTaskRequest(identifier: "com.greenroute.inactivity")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
        return didScheduleRecommendation
    }

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

    private static func recommendationsForToday(
        repository: any RecommendationRepository,
        now: Date,
        calendar: Calendar
    ) async throws -> [Recommendation] {
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
        return try await repository.fetch(from: start, to: end)
    }

    private static func maxDistance(from settings: AppSettings) -> DistanceMeters {
        DistanceMeters(value: Double(settings.maxRouteDurationMinutes) * 60.0 * 1.4 / 2.0)
    }
}
