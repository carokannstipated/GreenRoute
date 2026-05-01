// SwiftData entity for persisting an InactivityEvent domain model.

import Foundation
import SwiftData

/// Persistent storage representation of an `InactivityEvent`.
///
/// All fields are native Swift types so no raw-string encoding is needed.
/// `InactivityEventMapper` handles conversion to and from the domain model.
@Model
public final class InactivityEventEntity {
    /// Unique identifier. The `.unique` attribute enforces upsert semantics.
    @Attribute(.unique) public var id: UUID
    public var start: Date
    public var end: Date

    public init(id: UUID, start: Date, end: Date) {
        self.id = id
        self.start = start
        self.end = end
    }
}
