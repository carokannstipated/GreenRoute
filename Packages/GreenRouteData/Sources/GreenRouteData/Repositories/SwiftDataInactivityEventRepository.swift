
// SwiftData-backed implementation of InactivityEventRepository.

import Foundation
import SwiftData
import GreenRouteDomain

/// Persists and retrieves `InactivityEvent` domain models using SwiftData.
///
/// Each method creates its own `ModelContext` so the repository is safe to call from
/// any async context. Marked `@unchecked Sendable` because `ModelContainer` is thread-safe
/// but not formally `Sendable` in this version of SwiftData.
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

    /// Returns events whose `start` falls within [start, end), sorted most-recent first.
    /// The secondary sort by `id` provides a stable, deterministic order when two events
    /// share the same start time.
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
 
