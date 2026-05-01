// Central view model for the Green Break feature. Starts the background service,
// listens for inactivity and location events, and drives green break recommendations.

import Foundation
import UserNotifications
import GreenRouteDomain
import GreenRouteData
import GreenRouteService

/// Drives the Green Break home screen. Coordinates service lifecycle, reacts to
/// inactivity and location events, and exposes state for the view to render.
@MainActor
@Observable
final class GreenBreakViewModel {

    // MARK: - Published state

    /// The active recommendation to display, or nil when the app is idle.
    var recommendation: Recommendation?
    /// True when the route map sheet should be visible.
    var isShowingMap = false
    /// True while the user has accepted a recommendation and started walking.
    var isWalking = false
    /// Non-nil when a use-case or service call fails; shown as an alert.
    var errorMessage: String?
    /// True when a manual on-demand search completed but found no green areas within range.
    var noResultsNearby = false

    // MARK: - Derived / forwarded state

    /// The user's last known coordinate, read from the shared LocationStore.
    var lastKnownCoordinate: Coordinate? { locationStore.lastKnownCoordinate }
    /// Number of notifications scheduled today, used to enforce the daily cap.
    private var sentCountToday = 0
    /// Timestamp of the last scheduled notification, used to enforce the minimum interval.
    private var lastNotificationSentAt: Date?
    /// Long-running task that consumes the service event stream. Cancelled on stop().
    private var observationTask: Task<Void, Never>?

    // MARK: - Dependencies

    private let service: any GreenRouteService
    private let useCase: GenerateGreenBreakUseCase
    /// Optional — omitted in unit tests that don't exercise persistence.
    private let recordUseCase: RecordInactivityEventUseCase?
    /// Optional — omitted in unit tests that don't exercise persistence.
    private let locationVisitRepository: (any LocationVisitRepository)?
    private let locationStore: LocationStore
    private let settingsRepository: any SettingsRepository
    private let policy: NotificationPolicy
    /// Exposed so the map sheet can calculate routes without going through the service.
    private(set) var routeProvider: any RouteProvider

    // MARK: - Constants

    /// Minimum inactivity window (minutes) used when constructing synthetic events for on-demand generation.
    private let inactivityThresholdMinutes = 2
    /// Search radius for green area lookups around the user's position.
    private let searchRadius = DistanceMeters(value: 500)

    /// The maximum walking distance derived from the user's preferred route duration setting.
    /// Assumes a walking speed of 1.4 m/s and uses only the outbound half of the trip.
    private var maxDistance: DistanceMeters {
        let minutes = settingsRepository.load().maxRouteDurationMinutes
        return DistanceMeters(value: Double(minutes) * 60.0 * 1.4 / 2.0)
    }

    /// Current max route duration read from settings, kept in sync via reloadSettings().
    var maxRouteDurationMinutes: Int

    // MARK: - Init

    init(
        service: any GreenRouteService,
        useCase: GenerateGreenBreakUseCase,
        recordUseCase: RecordInactivityEventUseCase? = nil,
        locationVisitRepository: (any LocationVisitRepository)? = nil,
        locationStore: LocationStore = LocationStore(),
        settingsRepository: any SettingsRepository = UserDefaultsSettingsRepository(),
        policy: NotificationPolicy = NotificationPolicy()
    ) {
        self.service = service
        self.useCase = useCase
        self.recordUseCase = recordUseCase
        self.locationVisitRepository = locationVisitRepository
        self.locationStore = locationStore
        self.settingsRepository = settingsRepository
        self.policy = policy
        self.routeProvider = service.routeProvider
        self.maxRouteDurationMinutes = settingsRepository.load().maxRouteDurationMinutes
    }

    // MARK: - Lifecycle

    /// Requests notification permission, starts listening for service events, then starts the service.
    /// Notification permission is requested here (on the main actor) before service.start() triggers
    /// the location prompt, so the two system prompts don't collide.
    func start() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])

        observationTask = Task { [weak self] in
            guard let self else { return }
            for await event in service.events {
                await self.handle(event)
            }
        }

        await service.start()
    }

    /// Cancels the event observation task and stops the underlying service.
    func stop() async {
        observationTask?.cancel()
        observationTask = nil
        await service.stop()
    }

    // MARK: - User actions

    /// Shows the route map sheet for the current recommendation.
    func acceptRecommendation() {
        isShowingMap = true
    }

    /// Re-opens the map sheet after the user has minimised it via the session pill.
    func resumeSession() {
        isShowingMap = true
    }

    /// Clears the active session, hiding both the recommendation card and the map sheet.
    func endSession() {
        recommendation = nil
        isShowingMap = false
        isWalking = false
    }

    /// Dismisses the recommendation card without ending the walking session.
    func dismissRecommendation() {
        recommendation = nil
    }

    /// Persists the updated duration setting and refreshes the local copy.
    func setMaxRouteDuration(_ value: Int) {
        maxRouteDurationMinutes = value
        var s = settingsRepository.load()
        s.maxRouteDurationMinutes = value
        settingsRepository.save(s)
    }

    /// Re-reads the max duration from settings. Called when the view re-appears to pick up
    /// changes made via the Settings tab.
    func reloadSettings() {
        maxRouteDurationMinutes = settingsRepository.load().maxRouteDurationMinutes
    }

    // MARK: - Debug / on-demand

    /// DEBUG: Creates a synthetic two-minute inactivity event and triggers recommendation generation.
    /// Falls back to a hardcoded Copenhagen coordinate if no location is available.
    func simulateInactivity() async {
        let now = Date()
        let fakeEvent = InactivityEvent(
            start: now.addingTimeInterval(-TimeInterval(inactivityThresholdMinutes * 60)),
            end: now
        )
        let coordinate = lastKnownCoordinate ?? Coordinate(latitude: 55.6761, longitude: 12.5683)
        await generateRecommendation(for: fakeEvent, at: coordinate)
    }

    /// Manually triggers a green area search without scheduling a notification.
    /// Used when the user taps "Generate Green Route" from the idle state.
    func generateOnDemand() async {
        noResultsNearby = false

        let now = Date()
        let coordinate = lastKnownCoordinate ?? Coordinate(latitude: 55.6761, longitude: 12.5683)
        let fakeEvent = InactivityEvent(
            start: now.addingTimeInterval(-TimeInterval(inactivityThresholdMinutes * 60)),
            end: now
        )

        do {
            let output = try await useCase.execute(
                inactivity: fakeEvent,
                currentCoordinate: coordinate,
                inactivityThresholdMinutes: inactivityThresholdMinutes,
                maxDistance: maxDistance,
                searchRadius: searchRadius,
                sentCountToday: sentCountToday,
                lastNotificationSentAt: lastNotificationSentAt,
                shouldScheduleNotification: false, // on-demand requests never send a notification
                now: now
            )

            if let reco = output.recommendation {
                recommendation = reco
            } else {
                noResultsNearby = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private

    /// Routes incoming service events to the appropriate handler.
    private func handle(_ event: ServiceEvent) async {
        switch event {
        case .inactivityDetected(let inactivity):
            // Persist the raw inactivity event before attempting to generate a recommendation.
            try? await recordUseCase?.execute(inactivity)
            guard let coordinate = lastKnownCoordinate else { return }
            await generateRecommendation(for: inactivity, at: coordinate)
        case .significantLocationChange(let lat, let lon):
            locationStore.lastKnownCoordinate = Coordinate(latitude: lat, longitude: lon)
        case .locationVisit(let visit):
            locationStore.lastKnownCoordinate = visit.coordinate
            try? await locationVisitRepository?.save(visit)
        }
    }

    /// Runs the green break use case for the given inactivity event and location.
    /// Updates the recommendation if the use case returns one, and tracks notification scheduling
    /// so daily cap and minimum interval constraints are enforced on subsequent calls.
    private func generateRecommendation(for inactivity: InactivityEvent, at coordinate: Coordinate) async {
        do {
            let output = try await useCase.execute(
                inactivity: inactivity,
                currentCoordinate: coordinate,
                inactivityThresholdMinutes: inactivityThresholdMinutes,
                maxDistance: maxDistance,
                searchRadius: searchRadius,
                sentCountToday: sentCountToday,
                lastNotificationSentAt: lastNotificationSentAt,
                shouldScheduleNotification: true,
                now: Date()
            )

            if let reco = output.recommendation {
                recommendation = reco
            }

            if output.didScheduleNotification {
                sentCountToday += 1
                lastNotificationSentAt = Date()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
