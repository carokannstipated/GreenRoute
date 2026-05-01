
// Integration tests for SwiftDataLocationVisitRepository against an in-memory SwiftData store.

import XCTest
@testable import GreenRouteData
import GreenRouteDomain

final class SwiftDataLocationVisitRepositoryTests: XCTestCase {

    // MARK: - Round-trip serialisation

    /// A completed visit (with a departure) must survive save → fetch with all fields intact,
    /// including placeCategory and coordinate.
    func test_saveAndFetch_roundTripsCompletedVisit() async throws {
        let container = try ModelContainerFactory.makeInMemoryContainer()
        let repo = SwiftDataLocationVisitRepository(container: container)

        let arrival = ISO8601DateFormatter().date(from: "2026-02-01T12:00:00Z")!
        let departure = ISO8601DateFormatter().date(from: "2026-02-01T12:15:00Z")!

        let visit = LocationVisit(
            coordinate: Coordinate(latitude: 55.6761, longitude: 12.5683),
            arrival: arrival,
            departure: departure,
            placeCategory: .home
        )

        try await repo.save(visit)

        let results = try await repo.fetch(
            from: arrival.addingTimeInterval(-60),
            to: departure.addingTimeInterval(60)
        )

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first, visit)
    }

    /// An ongoing visit (departure == nil) must survive round-trip and `isOngoing` must be true.
    func test_saveAndFetch_roundTripsOngoingVisit() async throws {
        let container = try ModelContainerFactory.makeInMemoryContainer()
        let repo = SwiftDataLocationVisitRepository(container: container)

        let arrival = ISO8601DateFormatter().date(from: "2026-02-01T12:00:00Z")!

        let visit = LocationVisit(
            coordinate: Coordinate(latitude: 55.6761, longitude: 12.5683),
            arrival: arrival,
            departure: nil,
            placeCategory: .other
        )

        try await repo.save(visit)

        let results = try await repo.fetch(
            from: arrival.addingTimeInterval(-60),
            to: arrival.addingTimeInterval(60)
        )

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first, visit)
        XCTAssertTrue(results.first?.isOngoing ?? false)
    }

    // MARK: - Sort order

    /// When two visits are saved, the result must be ordered by arrival descending
    /// (most-recent visit first).
    func test_fetch_sortsByArrivalDescending() async throws {
        let container = try ModelContainerFactory.makeInMemoryContainer()
        let repo = SwiftDataLocationVisitRepository(container: container)

        let t1 = ISO8601DateFormatter().date(from: "2026-02-01T12:00:00Z")!
        let t2 = ISO8601DateFormatter().date(from: "2026-02-01T13:00:00Z")!

        let older = LocationVisit(
            coordinate: Coordinate(latitude: 55.6761, longitude: 12.5683),
            arrival: t1,
            departure: t1.addingTimeInterval(60),
            placeCategory: .workOrStudy
        )

        let newer = LocationVisit(
            coordinate: Coordinate(latitude: 55.6761, longitude: 12.5683),
            arrival: t2,
            departure: t2.addingTimeInterval(60),
            placeCategory: .home
        )

        try await repo.save(older)
        try await repo.save(newer)

        let results = try await repo.fetch(
            from: t1.addingTimeInterval(-60),
            to: t2.addingTimeInterval(60)
        )

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0], newer)
        XCTAssertEqual(results[1], older)
    }
}

