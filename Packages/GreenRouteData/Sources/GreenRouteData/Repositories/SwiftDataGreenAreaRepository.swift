


// SwiftData-backed implementation of GreenAreaRepository.

import Foundation
import SwiftData
import GreenRouteDomain

/// Persists and retrieves `GreenArea` domain models using SwiftData.
///
/// Each method creates its own `ModelContext` so the repository is safe to call from
/// any async context. Marked `@unchecked Sendable` because `ModelContainer` is thread-safe
/// but not formally `Sendable` in this version of SwiftData.
public final class SwiftDataGreenAreaRepository: GreenAreaRepository, @unchecked Sendable {

    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    /// Maps the domain model to an entity and inserts it; a `.unique` constraint on `id`
    /// means inserting an area with an existing ID will update it in place.
    public func save(_ greenArea: GreenArea) async throws {
        let context = ModelContext(container)
        let entity = GreenAreaMapper.toEntity(greenArea)
        context.insert(entity)
        try context.save()
    }

    /// Returns all persisted green areas sorted alphabetically by name.
    public func fetchAll() async throws -> [GreenArea] {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<GreenAreaEntity>(
            sortBy: [SortDescriptor(\.name)]
        )
        let entities = try context.fetch(descriptor)
        return entities.map(GreenAreaMapper.toDomain)
    }
}
