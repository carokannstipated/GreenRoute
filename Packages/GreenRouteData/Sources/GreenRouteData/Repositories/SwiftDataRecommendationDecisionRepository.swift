

// SwiftData-backed implementation of RecommendationDecisionRepository.

import Foundation
import SwiftData
import GreenRouteDomain

/// Persists and retrieves `RecommendationDecision` domain models using SwiftData.
///
/// `save` and `fetch` are synchronous despite the protocol declaring `async throws`,
/// because SwiftData operations on a freshly created `ModelContext` are synchronous.
/// Swift allows a synchronous conformance where the protocol requires `async`.
///
/// Marked `@unchecked Sendable` because `ModelContainer` is thread-safe but not
/// formally `Sendable` in this version of SwiftData.
public final class SwiftDataRecommendationDecisionRepository: RecommendationDecisionRepository, @unchecked Sendable {

    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func save(_ decision: RecommendationDecision) throws {
        let context = ModelContext(container)
        let entity = RecommendationDecisionMapper.toEntity(decision)
        context.insert(entity)
        try context.save()
    }

    /// Returns all decisions for the given recommendation ID, sorted most-recent first.
    public func fetch(for recommendationID: UUID) throws -> [RecommendationDecision] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<RecommendationDecisionEntity>(
            predicate: #Predicate { $0.recommendationID == recommendationID },
            sortBy: [
                SortDescriptor(\.timestamp, order: .reverse),
                SortDescriptor(\.id, order: .reverse)
            ]
        )
        let entities = try context.fetch(descriptor)
        return entities.map(RecommendationDecisionMapper.toDomain)
    }
}
