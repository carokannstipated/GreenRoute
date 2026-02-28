//
//  RecommendationEngineTests.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import XCTest
@testable import GreenRouteDomain

final class RecommendationEngineTests: XCTestCase {

    func test_generateRecommendation_returnsRecommendation_whenInactiveAndWithinDistance() throws {
        let engine = RecommendationEngine()

        let current = Coordinate(latitude: 55.6761, longitude: 12.5683)

        // Make the destination exactly the same coordinate to eliminate distance flakiness.
        let nearPark = GreenArea(
            id: "park-1",
            name: "Nearby Park",
            coordinate: current,
            kind: .park
        )

        let inactivity = InactivityEvent(
            start: iso("2026-02-01T12:00:00Z"),
            end: iso("2026-02-01T12:35:00Z") // 35 minutes
        )

        let createdAt = iso("2026-02-01T12:35:01Z")

        let recommendation = engine.generateRecommendation(
            inactivity: inactivity,
            currentCoordinate: current,
            nearbyGreenAreas: [nearPark],
            inactivityThresholdMinutes: 20,
            maxDistance: DistanceMeters(value: 1000),
            createdAt: createdAt
        )
        
        let unwrapped = try XCTUnwrap(recommendation)
        XCTAssertEqual(unwrapped.trigger, .inactivity)
        XCTAssertEqual(unwrapped.target, nearPark)
        XCTAssertLessThanOrEqual(unwrapped.distance.value, 1000)
        XCTAssertGreaterThanOrEqual(unwrapped.estimatedWalkMinutes, 0)
        XCTAssertEqual(unwrapped.createdAt, createdAt)
    }

    func test_generateRecommendation_returnsNil_whenInactivityBelowThreshold() {
        let engine = RecommendationEngine()

        let current = Coordinate(latitude: 55.6761, longitude: 12.5683)
        let nearPark = GreenArea(
            id: "park-1",
            name: "Nearby Park",
            coordinate: Coordinate(latitude: 55.6762, longitude: 12.5683),
            kind: .park
        )

        // Only 10 minutes inactivity
        let inactivity = InactivityEvent(
            start: iso("2026-02-01T12:00:00Z"),
            end: iso("2026-02-01T12:10:00Z")
        )

        let recommendation = engine.generateRecommendation(
            inactivity: inactivity,
            currentCoordinate: current,
            nearbyGreenAreas: [nearPark],
            inactivityThresholdMinutes: 20,
            maxDistance: DistanceMeters(value: 500),
            createdAt: iso("2026-02-01T12:10:01Z")
        )

        XCTAssertNil(recommendation)
    }

    func test_generateRecommendation_returnsNil_whenNearestGreenAreaTooFar() {
        let engine = RecommendationEngine()

        let current = Coordinate(latitude: 55.6761, longitude: 12.5683)

        // Far away green area
        let farPark = GreenArea(
            id: "park-2",
            name: "Far Park",
            coordinate: Coordinate(latitude: 55.6900, longitude: 12.5683),
            kind: .park
        )

        let inactivity = InactivityEvent(
            start: iso("2026-02-01T12:00:00Z"),
            end: iso("2026-02-01T12:40:00Z")
        )

        let recommendation = engine.generateRecommendation(
            inactivity: inactivity,
            currentCoordinate: current,
            nearbyGreenAreas: [farPark],
            inactivityThresholdMinutes: 20,
            maxDistance: DistanceMeters(value: 500),
            createdAt: iso("2026-02-01T12:40:01Z")
        )

        XCTAssertNil(recommendation)
    }
}

// MARK: - Helpers

private func iso(_ value: String) -> Date {
    ISO8601DateFormatter().date(from: value)!
}
