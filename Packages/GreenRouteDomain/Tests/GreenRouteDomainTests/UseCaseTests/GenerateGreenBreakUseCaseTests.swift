// Tests for GenerateGreenBreakUseCase — verifies the full recommendation and notification pipeline.

import XCTest
@testable import GreenRouteDomain

final class GenerateGreenBreakUseCaseTests: XCTestCase {

    // MARK: - Full happy path

    /// When all conditions are met (inactivity threshold, nearby park, policy allows),
    /// the use case must save the recommendation AND schedule the notification.
    func test_execute_generatesAndSavesRecommendation_andSchedulesNotification_whenAllowed() async throws {
        let provider = FakeGreenAreaProvider(areas: [
            GreenArea(
                id: "park-1",
                name: "Nearby Park",
                coordinate: Coordinate(latitude: 55.6761, longitude: 12.5683),
                kind: .park
            )
        ])

        let repo = FakeRecommendationRepository()
        let scheduler = FakeNotificationScheduler()

        let useCase = GenerateGreenBreakUseCase(
            greenAreaProvider: provider,
            recommendationEngine: RecommendationEngine(),
            recommendationRepository: repo,
            notificationPolicy: NotificationPolicy(maxPerDay: 2, minimumInterval: 0),
            notificationScheduler: scheduler
        )

        let now = iso("2026-02-01T12:35:01Z")
        let inactivity = InactivityEvent(
            start: iso("2026-02-01T12:00:00Z"),
            end: iso("2026-02-01T12:35:00Z")
        )

        // Park coordinate matches current position, so distance == 0 and the engine accepts it.
        let current = Coordinate(latitude: 55.6761, longitude: 12.5683)

        let output = try await useCase.execute(
            inactivity: inactivity,
            currentCoordinate: current,
            inactivityThresholdMinutes: 20,
            maxDistance: DistanceMeters(value: 1000),
            searchRadius: DistanceMeters(value: 1000),
            sentCountToday: 0,
            lastNotificationSentAt: nil,
            shouldScheduleNotification: true,
            now: now
        )

        let reco = try XCTUnwrap(output.recommendation)

        let saved = await repo.allSaved()
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first, reco)

        XCTAssertTrue(output.didScheduleNotification)

        // The notification ID must contain the recommendation UUID so it can be cancelled later.
        let scheduled = await scheduler.allScheduled()
        XCTAssertEqual(scheduled.count, 1)
        XCTAssertTrue(scheduled[0].id.contains(reco.id.uuidString))
    }

    // MARK: - Policy blocks notification

    /// When the daily cap is already reached (sentCountToday == maxPerDay), the recommendation
    /// must still be saved but no notification should be scheduled.
    func test_execute_generatesAndSavesRecommendation_butDoesNotSchedule_whenPolicyBlocks() async throws {
        let provider = FakeGreenAreaProvider(areas: [
            GreenArea(
                id: "park-1",
                name: "Nearby Park",
                coordinate: Coordinate(latitude: 55.6761, longitude: 12.5683),
                kind: .park
            )
        ])

        let repo = FakeRecommendationRepository()
        let scheduler = FakeNotificationScheduler()

        let useCase = GenerateGreenBreakUseCase(
            greenAreaProvider: provider,
            recommendationEngine: RecommendationEngine(),
            recommendationRepository: repo,
            notificationPolicy: NotificationPolicy(maxPerDay: 1, minimumInterval: 0),
            notificationScheduler: scheduler
        )

        let now = iso("2026-02-01T12:35:01Z")
        let inactivity = InactivityEvent(
            start: iso("2026-02-01T12:00:00Z"),
            end: iso("2026-02-01T12:35:00Z")
        )

        let current = Coordinate(latitude: 55.6761, longitude: 12.5683)

        // sentCountToday: 1 == maxPerDay: 1, so the policy must block.
        let output = try await useCase.execute(
            inactivity: inactivity,
            currentCoordinate: current,
            inactivityThresholdMinutes: 20,
            maxDistance: DistanceMeters(value: 1000),
            searchRadius: DistanceMeters(value: 1000),
            sentCountToday: 1,
            lastNotificationSentAt: nil,
            shouldScheduleNotification: true,
            now: now
        )

        _ = try XCTUnwrap(output.recommendation)

        let saved = await repo.allSaved()
        XCTAssertEqual(saved.count, 1)

        XCTAssertFalse(output.didScheduleNotification)

        let scheduled = await scheduler.allScheduled()
        XCTAssertEqual(scheduled.count, 0)
    }
}

// MARK: - Test doubles

/// Returns a fixed list of green areas regardless of the requested coordinate or radius.
private struct FakeGreenAreaProvider: GreenAreaProvider {
    let areas: [GreenArea]
    func fetchGreenAreas(near coordinate: Coordinate, radius: DistanceMeters) async throws -> [GreenArea] {
        areas
    }
}

/// In-memory recommendation store that accumulates every saved recommendation.
private actor FakeRecommendationRepository: RecommendationRepository {
    private var saved: [Recommendation] = []

    func save(_ recommendation: Recommendation) async throws {
        saved.append(recommendation)
    }

    func fetch(from start: Date, to end: Date) async throws -> [Recommendation] {
        saved.filter { $0.createdAt >= start && $0.createdAt < end }
    }

    func allSaved() -> [Recommendation] { saved }
}

/// In-memory notification scheduler that records every scheduled request.
private actor FakeNotificationScheduler: NotificationScheduler {
    private var scheduled: [NotificationRequest] = []

    func schedule(_ request: NotificationRequest) async throws {
        scheduled.append(request)
    }

    func allScheduled() -> [NotificationRequest] { scheduled }
}

// MARK: - Helpers

private func iso(_ value: String) -> Date {
    ISO8601DateFormatter().date(from: value)!
}
