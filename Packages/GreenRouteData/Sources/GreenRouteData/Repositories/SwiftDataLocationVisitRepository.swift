//
//  SwiftDataLocationVisitRepository.swift
//  GreenRouteData
//
//  Created by David Rivera on 04/03/2026.
//

import Foundation
import SwiftData
import GreenRouteDomain

public final class SwiftDataLocationVisitRepository: LocationVisitRepository, @unchecked Sendable {
    
    private let container: ModelContainer
    
    public init(container: ModelContainer) {
        self.container = container
    }
    public func save(_ visit: LocationVisit) async throws {
           let context = ModelContext(container)
           let entity = LocationVisitMapper.toEntity(visit)
           context.insert(entity)
           try context.save()
       }

    public func fetch(from start: Date, to end: Date) async throws -> [LocationVisit] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<LocationVisitEntity>(
            predicate: #Predicate { $0.arrival >= start && $0.arrival < end },
            sortBy: [
                SortDescriptor(\.arrival, order: .reverse),
                SortDescriptor(\.id, order: .reverse)
            ]
        )
        let entities = try context.fetch(descriptor)
        return entities.map(LocationVisitMapper.toDomain)
    }
    
}

