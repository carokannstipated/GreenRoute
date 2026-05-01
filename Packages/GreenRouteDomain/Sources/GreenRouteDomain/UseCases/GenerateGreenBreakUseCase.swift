// Orchestrates the full pipeline from inactivity detection to green-break notification delivery.

import Foundation

/// Coordinates green-area lookup, recommendation generation, persistence, and notification scheduling.
///
/// This is the primary entry point for the recommendation flow. It chains five collaborators:
/// `GreenAreaProvider` → `RecommendationEngine` → `RecommendationRepository` →
/// `NotificationPolicy` → `NotificationScheduler`.
///
/// A recommendation is always saved to the repository if the engine produces one, regardless
/// of whether a notification is ultimately sent.
public struct GenerateGreenBreakUseCase: Sendable {

    /// The result of a single execution, returned whether or not a notification was sent.
    public struct Output: Equatable, Sendable {

        /// The recommendation produced by the engine, or `nil` if the engine rejected the input.
        public let recommendation: Recommendation?

        /// `true` only when a `NotificationRequest` was successfully handed to the scheduler.
        public let didScheduleNotification: Bool

        public init(recommendation: Recommendation?, didScheduleNotification: Bool) {
            self.recommendation = recommendation
            self.didScheduleNotification = didScheduleNotification
        }
    }

    private let greenAreaProvider: GreenAreaProvider
    private let recommendationEngine: RecommendationEngine
    private let recommendationRepository: RecommendationRepository
    private let notificationPolicy: NotificationPolicy
    private let notificationScheduler: NotificationScheduler

    public init(
        greenAreaProvider: GreenAreaProvider,
        recommendationEngine: RecommendationEngine,
        recommendationRepository: RecommendationRepository,
        notificationPolicy: NotificationPolicy,
        notificationScheduler: NotificationScheduler
    ) {
        self.greenAreaProvider = greenAreaProvider
        self.recommendationEngine = recommendationEngine
        self.recommendationRepository = recommendationRepository
        self.notificationPolicy = notificationPolicy
        self.notificationScheduler = notificationScheduler
    }

    /// Runs the recommendation pipeline for the given inactivity event.
    ///
    /// - Parameters:
    ///   - inactivity: The inactivity event that triggered this evaluation.
    ///   - currentCoordinate: The user's current location.
    ///   - inactivityThresholdMinutes: Minimum inactivity length before a recommendation is considered.
    ///   - maxDistance: Upper distance bound for the recommended green area.
    ///   - searchRadius: Radius passed to `GreenAreaProvider.fetchGreenAreas`.
    ///   - sentCountToday: Notification count already sent today, forwarded to `NotificationPolicy`.
    ///   - lastNotificationSentAt: Timestamp of the last sent notification, forwarded to `NotificationPolicy`.
    ///   - shouldScheduleNotification: When `false`, skips scheduling entirely (e.g. notification
    ///     permission not granted, or called from a background context without permission).
    ///   - now: The current time; used as `createdAt` for the recommendation and for policy checks.
    ///   - trigger: What initiated this call; defaults to `.inactivity`.
    public func execute(
        inactivity: InactivityEvent,
        currentCoordinate: Coordinate,
        inactivityThresholdMinutes: Int,
        maxDistance: DistanceMeters,
        searchRadius: DistanceMeters,
        sentCountToday: Int,
        lastNotificationSentAt: Date?,
        shouldScheduleNotification: Bool,
        now: Date,
        trigger: Recommendation.Trigger = .inactivity
    ) async throws -> Output {

        let areas = try await greenAreaProvider.fetchGreenAreas(
            near: currentCoordinate,
            radius: searchRadius
        )

        #if DEBUG
        print("🟡 fetchGreenAreas returned \(areas.count) areas near \(currentCoordinate)")
        #endif

        guard let recommendation = recommendationEngine.generateRecommendation(
            inactivity: inactivity,
            currentCoordinate: currentCoordinate,
            nearbyGreenAreas: areas,
            inactivityThresholdMinutes: inactivityThresholdMinutes,
            maxDistance: maxDistance,
            createdAt: now,
            trigger: trigger
        ) else {
            return Output(recommendation: nil, didScheduleNotification: false)
        }

        // Always persist the recommendation, even if we end up not sending a notification.
        try await recommendationRepository.save(recommendation)

        guard shouldScheduleNotification else {
            return Output(recommendation: recommendation, didScheduleNotification: false)
        }

        let canSend = notificationPolicy.canSend(
            sentCountToday: sentCountToday,
            lastSentAt: lastNotificationSentAt,
            now: now
        )

        guard canSend else {
            return Output(recommendation: recommendation, didScheduleNotification: false)
        }

        // `fireAt` is 1 second in the future rather than exactly `now` because
        // `UNNotificationCenter` rejects requests with a trigger time in the past.
        let request = NotificationRequest(
            id: "greenroute.reco.\(recommendation.id.uuidString)",
            title: "Green break?",
            body: "\(recommendation.target.name) is \(Int(recommendation.distance.value))m away (~\(recommendation.estimatedWalkMinutes) min walk).",
            fireAt: now.addingTimeInterval(1)
        )

        try await notificationScheduler.schedule(request)

        return Output(recommendation: recommendation, didScheduleNotification: true)
    }
}
