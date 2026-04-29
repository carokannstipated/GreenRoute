//
//  GenerateGreenBreakUseCase.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import Foundation

public struct GenerateGreenBreakUseCase: Sendable {

    public struct Output: Equatable, Sendable {
        public let recommendation: Recommendation?
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

    // Evaluates context and creates a green-break recommendation if rules match.
    //
    // Scheduling a notification is optional and guarded by NotificationPolicy.
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

        // 1) Fetch nearby green areas (Platform implementation will do MapKit/POI)
        let areas = try await greenAreaProvider.fetchGreenAreas(
            near: currentCoordinate,
            radius: searchRadius
        )

        #if DEBUG
        print("🟡 fetchGreenAreas returned \(areas.count) areas near \(currentCoordinate)")
        #endif

        // 2) Generate recommendation (rule-based engine)
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

        // 3) Persist recommendation
        try await recommendationRepository.save(recommendation)
        
        // 4) Optionally schedule notification (anti-spam policy)
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
