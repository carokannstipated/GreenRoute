

// SwiftData-backed implementation of RecurringPatternRepository.

import Foundation
import SwiftData
import GreenRouteDomain

/// Persists and retrieves `RecurringPattern` domain models using SwiftData.
///
/// Patterns are ranked by evidence count then confidence, so the "best" known pattern
/// always appears first. Both `fetchAll` and `fetchLatest` use the same sort; `fetchLatest`
/// additionally applies a limit of 1.
///
/// Marked `@unchecked Sendable` because `ModelContainer` is thread-safe but not
/// formally `Sendable` in this version of SwiftData.
public final class SwiftDataRecurringPatternRepository: RecurringPatternRepository, @unchecked Sendable {

    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    /// Inserts or updates (upserts) a pattern. Because `id` carries the `.unique` attribute,
    /// saving a pattern with an existing ID updates it in place.
    public func save(_ pattern: RecurringPattern) async throws {
        let context = ModelContext(container)
        let entity = RecurringPatternMapper.toEntity(pattern)
        context.insert(entity)
        try context.save()
    }

    /// Returns all persisted patterns, sorted by evidence count descending, then confidence descending.
    public func fetchAll() async throws -> [RecurringPattern] {
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

    /// Returns the single best pattern (highest evidence count, then confidence), or `nil`
    /// if no pattern has been persisted yet. Uses `fetchLimit = 1` to avoid loading all records.
    public func fetchLatest() async throws -> GreenRouteDomain.RecurringPattern? {
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
}

