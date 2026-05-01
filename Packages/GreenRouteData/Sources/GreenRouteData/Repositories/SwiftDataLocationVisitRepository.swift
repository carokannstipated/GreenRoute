
// SwiftData-backed implementation of LocationVisitRepository.

import Foundation
import SwiftData
import GreenRouteDomain

/// Persists and retrieves `LocationVisit` domain models using SwiftData.
///
/// Each method creates its own `ModelContext` so the repository is safe to call from
/// any async context. Marked `@unchecked Sendable` because `ModelContainer` is thread-safe
/// but not formally `Sendable` in this version of SwiftData.
public final class SwiftDataLocationVisitRepository: LocationVisitRepository, @unchecked Sendable {

    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func save(_ visit: GreenRouteDomain.LocationVisit) async throws {
        let context = ModelContext(container)
        let entity = LocationVisitMapper.toEntity(visit)
        context.insert(entity)
        try context.save()
    }

    /// Returns visits whose `arrival` falls within [start, end), sorted most-recent first.
    /// The secondary sort by `id` gives a stable order when two visits share an arrival time.
    public func fetch(from start: Date, to end: Date) async throws -> [GreenRouteDomain.LocationVisit] {
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

