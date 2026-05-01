// SwiftData entity for persisting a RecurringPattern domain model.

import Foundation
import SwiftData

/// Persistent storage representation of a `RecurringPattern`.
///
/// The `TimeWindow` value type is flattened into `windowStartMinutes`/`windowEndMinutes`
/// because SwiftData cannot store arbitrary nested value types. `RecurringPatternMapper`
/// reconstructs the `TimeWindow` on read.
@Model
public final class RecurringPatternEntity {

    /// Unique identifier. The `.unique` attribute allows saving an updated pattern over an existing one.
    @Attribute(.unique) public var id: UUID
    /// Raw string representation of `RecurringPattern.Kind` (currently always "dailyTimeWindow").
    public var kindRaw: String
    /// Start of the detected time window in minutes from midnight.
    public var windowStartMinutes: Int
    /// End of the detected time window in minutes from midnight.
    public var windowEndMinutes: Int
    public var evidenceCount: Int
    public var confidence: Double

    public init(
        id: UUID,
        kindRaw: String,
        windowStartMinutes: Int,
        windowEndMinutes: Int,
        evidenceCount: Int,
        confidence: Double
    ) {
        self.id = id
        self.kindRaw = kindRaw
        self.windowStartMinutes = windowStartMinutes
        self.windowEndMinutes = windowEndMinutes
        self.evidenceCount = evidenceCount
        self.confidence = confidence
    }
}