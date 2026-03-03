//
//  SwiftDataRecommendationRepository.swift
//  GreenRouteData
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import Foundation
import SwiftData
import GreenRouteDomain

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
