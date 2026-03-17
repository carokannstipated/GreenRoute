//
//  SwiftDataRecommendationDecisionRepositoryTests.swift
//  GreenRouteData
//
//  Created by David Rivera on 17/03/2026.
//


import XCTest
import SwiftData
@testable import GreenRouteData
@testable import GreenRouteDomain

final class SwiftDataRecommendationDecisionRepositoryTests: XCTestCase {

    private var container: ModelContainer!
    private var repository: SwiftDataRecommendationDecisionRepository!

    override func setUp() {
        do {
            let schema = Schema([
                RecommendationDecisionEntity.self
            ])

            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try ModelContainer(for: schema, configurations: config)
            repository = SwiftDataRecommendationDecisionRepository(container: container)
        } catch {
            XCTFail("Failed to set up ModelContainer: \(error)")
        }
    }

    override func tearDown() {
        container = nil
        repository = nil
    }

    func test_saveAndFetchDecision() async throws {
        // Given
        let recommendationID = UUID()

        let decision = RecommendationDecision(
            recommendationID: recommendationID,
            decision: .accepted,
            timestamp: Date()
        )

        // When
        try await repository.save(decision)
        let fetched = try await repository.fetch(for: recommendationID)

        // Then
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.recommendationID, recommendationID)
        XCTAssertEqual(fetched.first?.decision, .accepted)
    }

    func test_fetchForUnknownRecommendationReturnsEmpty() async throws {
        // Given
        let unknownID = UUID()

        // When
        let fetched = try await repository.fetch(for: unknownID)

        // Then
        XCTAssertTrue(fetched.isEmpty)
    }

    func test_saveMultipleDecisionsAndFetchByRecommendationID() async throws {
        // Given
        let targetID = UUID()
        let otherID = UUID()

        let now = Date()
        let earlier = now.addingTimeInterval(-60)

        let decision1 = RecommendationDecision(
            recommendationID: targetID,
            decision: .accepted,
            timestamp: earlier
        )
        let decision2 = RecommendationDecision(
            recommendationID: targetID,
            decision: .dismissed,
            timestamp: now
        )
        let otherDecision = RecommendationDecision(
            recommendationID: otherID,
            decision: .accepted,
            timestamp: now
        )

        // When
        try await repository.save(decision1)
        try await repository.save(decision2)
        try await repository.save(otherDecision)

        let fetched = try await repository.fetch(for: targetID)

        // Then
        XCTAssertEqual(fetched.count, 2)
        XCTAssertTrue(fetched.allSatisfy { $0.recommendationID == targetID })
        let fetchedDecisions = Set(fetched.map { $0.decision })
        XCTAssertEqual(fetchedDecisions, Set([.accepted, .dismissed]))
    }
}
