//
//  SwiftDataRecurringPatternRepository.swift
//  GreenRouteData
//
//  Created by David Rivera on 17/03/2026.
//


import Foundation
import SwiftData
import GreenRouteDomain

public final class SwiftDataRecurringPatternRepository: RecurringPatternRepository, @unchecked Sendable {
    public func fetchLatest() throws -> GreenRouteDomain.RecurringPattern? {
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<RecurringPatternEntity>(
            sortBy: [
                SortDescriptor(\.evidenceCount, order: .reverse),
                SortDescriptor(\.confidence, order: .reverse)
            ]
        )
        descriptor.fetchLimit = 1
        let entities = try context.fetch(descriptor)
        return entities.first.map(RecurringPatternMapper.toDomain)
    }
    
    
    private let container: ModelContainer
    
    public init(container: ModelContainer) {
        self.container = container
    }
    
    public func save(_ pattern: RecurringPattern) throws {
        let context = ModelContext(container)
        let entity = RecurringPatternMapper.toEntity(pattern)
        context.insert(entity)
        try context.save()
    }
    
    public func fetchAll() throws -> [RecurringPattern] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<RecurringPatternEntity>(
            sortBy: [
                SortDescriptor(\.evidenceCount, order: .reverse),
                SortDescriptor(\.confidence, order: .reverse)
            ]
        )
        let entities = try context.fetch(descriptor)
        return entities.map(RecurringPatternMapper.toDomain)
    }
}

