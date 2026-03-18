//
//  SwiftDataRecommendationDecisionRepository.swift
//  GreenRouteData
//
//  Created by David Rivera on 17/03/2026.
//


import Foundation
import SwiftData
import GreenRouteDomain

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
