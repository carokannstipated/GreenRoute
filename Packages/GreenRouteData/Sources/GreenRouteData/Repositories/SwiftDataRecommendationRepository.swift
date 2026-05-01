
// SwiftData-backed implementation of RecommendationRepository.

import Foundation
import SwiftData
import GreenRouteDomain

/// Persists and retrieves `Recommendation` domain models using SwiftData.
///
/// Each method creates its own `ModelContext` so the repository is safe to call from
/// any async context. Marked `@unchecked Sendable` because `ModelContainer` is thread-safe
/// but not formally `Sendable` in this version of SwiftData.
public final class SwiftDataRecommendationRepository: RecommendationRepository, @unchecked Sendable {

    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func save(_ recommendation: Recommendation) async throws {
        let context = ModelContext(container)
        let entity = RecommendationMapper.toEntity(recommendation)
        context.insert(entity)
        try context.save()
    }

    /// Returns recommendations whose `createdAt` falls within [start, end), sorted most-recent first.
    public func fetch(from start: Date, to end: Date) async throws -> [Recommendation] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<RecommendationEntity>(
            predicate: #Predicate { $0.createdAt >= start && $0.createdAt < end },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let entities = try context.fetch(descriptor)
        return entities.map(RecommendationMapper.toDomain)
    }
}
