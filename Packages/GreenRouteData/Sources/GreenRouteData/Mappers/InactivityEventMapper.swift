// Bidirectional mapper between the InactivityEvent domain model and its SwiftData entity.

import Foundation
import GreenRouteDomain

/// Translates `InactivityEvent` ↔ `InactivityEventEntity`.
///
/// All fields are native Swift types (UUID, Date), so no raw-string encoding is needed.
enum InactivityEventMapper {

    /// Converts a domain `InactivityEvent` to a SwiftData entity ready for insertion.
    static func toEntity(_ model: InactivityEvent) -> InactivityEventEntity {
        InactivityEventEntity(id: model.id, start: model.start, end: model.end)
    }

    /// Reconstructs an `InactivityEvent` domain model from a persisted entity.
    static func toDomain(_ entity: InactivityEventEntity) -> InactivityEvent {
        InactivityEvent(id: entity.id, start: entity.start, end: entity.end)
    }
}
