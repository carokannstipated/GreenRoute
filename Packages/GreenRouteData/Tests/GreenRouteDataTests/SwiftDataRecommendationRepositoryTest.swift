//
//  SwiftDataRecommendationRepositoryTest.swift
//  GreenRouteData
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import XCTest
import SwiftData
import GreenRouteDomain
@testable import GreenRouteData

final class SwiftDataRecommendationRepositoryTests: XCTestCase {

    func test_saveAndFetch_roundTripsRecommendation() async throws {
        let container = try ModelContainerFactory.makeInMemoryContainer()
        let repo = SwiftDataRecommendationRepository(container: container)

        let now = ISO8601DateFormatter().date(from: "2026-02-01T12:00:00Z")!
        let target = GreenArea(
            id: "park-1",
            name: "Nearby Park",
            coordinate: Coordinate(latitude: 55.6761, longitude: 12.5683),
            kind: .park
        )

        let reco = Recommendation(
            createdAt: now,
            trigger: .inactivity,
            target: target,
            distance: DistanceMeters(value: 123),
            estimatedWalkMinutes: 2
        )

        try await repo.save(reco)

        let results = try await repo.fetch(
            from: now.addingTimeInterval(-60),
            to: now.addingTimeInterval(60)
        )

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first, reco)
    }
}
