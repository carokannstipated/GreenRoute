//
//  SwiftDataGreenAreaRepository.swift
//  GreenRouteData
//
//  Created by David Rivera on 17/03/2026.
//

//  This Repo might be used for favorites or other reasons to save a greenarea
//  For fetching a green area from the map look to protocols -> providers -> GreenAreaProvider


import Foundation
import SwiftData
import GreenRouteDomain

public final class SwiftDataGreenAreaRepository: GreenAreaRepository, @unchecked Sendable {

    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func save(_ greenArea: GreenArea) async throws {
        let context = ModelContext(container)
        let entity = GreenAreaMapper.toEntity(greenArea)
        context.insert(entity)
        try context.save()
    }

    public func fetchAll() async throws -> [GreenArea] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<GreenAreaEntity>(
            sortBy: [SortDescriptor(\.name)]
        )
        let entities = try context.fetch(descriptor)
        return entities.map(GreenAreaMapper.toDomain)
    }
}
