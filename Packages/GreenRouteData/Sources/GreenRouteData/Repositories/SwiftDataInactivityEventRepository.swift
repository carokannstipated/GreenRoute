//
//  SwiftDataInactivityEventRepository.swift
//  GreenRouteData
//
//  Created by David Rivera on 18/03/2026.
//

import Foundation
import SwiftData
import GreenRouteDomain
 
public final class SwiftDataInactivityEventRepository: InactivityEventRepository, @unchecked Sendable {
 
    private let container: ModelContainer
 
    public init(container: ModelContainer) {
        self.container = container
    }
 
    public func save(_ event: InactivityEvent) async throws {
        let context = ModelContext(container)
        let entity = InactivityEventMapper.toEntity(event)
        context.insert(entity)
        try context.save()
    }
 
    public func fetch(from start: Date, to end: Date) async throws -> [InactivityEvent] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<InactivityEventEntity>(
            predicate: #Predicate { $0.start >= start && $0.start < end },
            sortBy: [
                SortDescriptor(\.start, order: .reverse),
                SortDescriptor(\.id, order: .reverse)
            ]
        )
        let entities = try context.fetch(descriptor)
        return entities.map(InactivityEventMapper.toDomain)
    }
}
 
