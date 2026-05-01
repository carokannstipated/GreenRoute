

// Integration tests for SwiftDataRecommendationDecisionRepository against an in-memory SwiftData store.

import XCTest
import SwiftData
@testable import GreenRouteData
@testable import GreenRouteDomain

final class SwiftDataRecommendationDecisionRepositoryTests: XCTestCase {

    private var container: ModelContainer!
    private var repository: SwiftDataRecommendationDecisionRepository!

    /// Creates a fresh in-memory container before each test to ensure isolation.
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

    // MARK: - Save and fetch round-trip

    /// Saving a decision and fetching it back by recommendation ID must return that decision
    /// with the correct recommendationID and decision value preserved.
    func test_saveAndFetchDecision() async throws {
        let recommendationID = UUID()

        let decision = RecommendationDecision(
            recommendationID: recommendationID,
            decision: .accepted,
            timestamp: Date()
        )

        try await repository.save(decision)
        let fetched = try await repository.fetch(for: recommendationID)

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.recommendationID, recommendationID)
        XCTAssertEqual(fetched.first?.decision, .accepted)
    }

    // MARK: - Unknown ID

    /// Fetching decisions for a UUID that has never been saved must return an empty array.
    func test_fetchForUnknownRecommendationReturnsEmpty() async throws {
        let unknownID = UUID()

        let fetched = try await repository.fetch(for: unknownID)

        XCTAssertTrue(fetched.isEmpty)
    }

    // MARK: - Filtering by recommendation ID

    /// When decisions for multiple recommendation IDs exist in the store, only decisions
    /// belonging to the queried ID must be returned.
    func test_saveMultipleDecisionsAndFetchByRecommendationID() async throws {
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

        try await repository.save(decision1)
        try await repository.save(decision2)
        try await repository.save(otherDecision)

        let fetched = try await repository.fetch(for: targetID)

        XCTAssertEqual(fetched.count, 2)
        XCTAssertTrue(fetched.allSatisfy { $0.recommendationID == targetID })
        let fetchedDecisions = Set(fetched.map { $0.decision })
        XCTAssertEqual(fetchedDecisions, Set([.accepted, .dismissed]))
    }
}
