// Tests for RecommendationEngine — verifies the three rejection filters and a successful path.

import XCTest
@testable import GreenRouteDomain

final class RecommendationEngineTests: XCTestCase {

    // MARK: - Successful recommendation

    /// 35 minutes of inactivity exceeds the 20-minute threshold and the park is at distance 0 —
    /// the engine should produce a valid recommendation targeting that park.
    func test_generateRecommendation_returnsRecommendation_whenInactiveAndWithinDistance() throws {
        let engine = RecommendationEngine()

        let current = Coordinate(latitude: 55.6761, longitude: 12.5683)

        // Park placed at the exact current coordinate so distance == 0, guaranteeing it is within maxDistance.
        let nearPark = GreenArea(
            id: "park-1",
            name: "Nearby Park",
            coordinate: current,
            kind: .park
        )

        let inactivity = InactivityEvent(
            start: iso("2026-02-01T12:00:00Z"),
            end: iso("2026-02-01T12:35:00Z")
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

    // MARK: - Inactivity threshold rejection

    /// 10 minutes of inactivity is below the 20-minute threshold — engine must return nil.
    func test_generateRecommendation_returnsNil_whenInactivityBelowThreshold() {
        let engine = RecommendationEngine()

        let current = Coordinate(latitude: 55.6761, longitude: 12.5683)
        let nearPark = GreenArea(
            id: "park-1",
            name: "Nearby Park",
            coordinate: Coordinate(latitude: 55.6762, longitude: 12.5683),
            kind: .park
        )

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

    // MARK: - Distance rejection

    /// Park is ~1.5 km away which exceeds the 500 m maxDistance — engine must return nil
    /// even though the inactivity threshold (40 min > 20 min) is satisfied.
    func test_generateRecommendation_returnsNil_whenNearestGreenAreaTooFar() {
        let engine = RecommendationEngine()

        let current = Coordinate(latitude: 55.6761, longitude: 12.5683)

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


private func iso(_ value: String) -> Date {
    ISO8601DateFormatter().date(from: value)!
}
