//
//  GenerateGreenBreakUseCaseTests.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//


import XCTest
@testable import GreenRouteDomain

final class GenerateGreenBreakUseCaseTests: XCTestCase {

    func test_execute_generatesAndSavesRecommendation_andSchedulesNotification_whenAllowed() async throws {
        let provider = FakeGreenAreaProvider(areas: [
            GreenArea(
                id: "park-1",
                name: "Nearby Park",
                coordinate: Coordinate(latitude: 55.6761, longitude: 12.5683), // same as current => distance 0
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
        XCTAssertEqual(repo.saved.count, 1)
        XCTAssertEqual(repo.saved.first, reco)

        XCTAssertTrue(output.didScheduleNotification)
        XCTAssertEqual(scheduler.scheduled.count, 1)
        XCTAssertTrue(scheduler.scheduled[0].id.contains(reco.id.uuidString))
    }

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

        // maxPerDay = 1, and sentCountToday = 1 => blocked
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
        XCTAssertEqual(repo.saved.count, 1)

        XCTAssertFalse(output.didScheduleNotification)
        XCTAssertEqual(scheduler.scheduled.count, 0)
    }
}

// MARK: - Fakes

private struct FakeGreenAreaProvider: GreenAreaProvider {
    let areas: [GreenArea]
    func fetchGreenAreas(near coordinate: Coordinate, radius: DistanceMeters) async throws -> [GreenArea] {
        areas
    }
}

private final class FakeRecommendationRepository: RecommendationRepository {
    var saved: [Recommendation] = []

    func save(_ recommendation: Recommendation) throws {
        saved.append(recommendation)
    }

    func fetch(from start: Date, to end: Date) throws -> [Recommendation] {
        saved.filter { $0.createdAt >= start && $0.createdAt < end }
    }
}

private final class FakeNotificationScheduler: NotificationScheduler {
    var scheduled: [NotificationRequest] = []

    func schedule(_ request: NotificationRequest) async throws {
        scheduled.append(request)
    }
}

// MARK: - Helpers

private func iso(_ value: String) -> Date {
    ISO8601DateFormatter().date(from: value)!
}