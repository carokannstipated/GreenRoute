// Bidirectional mapper between the RecurringPattern domain model and its SwiftData entity.

import Foundation
import GreenRouteDomain

/// Translates `RecurringPattern` ↔ `RecurringPatternEntity`, flattening `TimeWindow`
/// into separate start/end fields and encoding the `Kind` enum as a raw `String`.
enum RecurringPatternMapper {

    /// Converts a domain `RecurringPattern` to a SwiftData entity ready for insertion.
    static func toEntity(_ model: RecurringPattern) -> RecurringPatternEntity {
        RecurringPatternEntity(
            id: model.id,
            kindRaw: kindRaw(model.kind),
            windowStartMinutes: model.window.startMinutes,
            windowEndMinutes: model.window.endMinutes,
            evidenceCount: model.evidenceCount,
            confidence: model.confidence
        )
    }

    /// Reconstructs a `RecurringPattern` domain model from a persisted entity,
    /// reassembling the `TimeWindow` from flat start/end minute fields.
    static func toDomain(_ entity: RecurringPatternEntity) -> RecurringPattern {
        RecurringPattern(
            id: entity.id,
            kind: kindFromRaw(entity.kindRaw),
            window: TimeWindow(
                startMinutes: entity.windowStartMinutes,
                endMinutes: entity.windowEndMinutes
            ),
            evidenceCount: entity.evidenceCount,
            confidence: entity.confidence
        )
    }

    /// Encodes a `Kind` to its canonical string representation.
    private static func kindRaw(_ kind: RecurringPattern.Kind) -> String {
        switch kind {
        case .dailyTimeWindow: return "dailyTimeWindow"
        }
    }

    /// Decodes a raw string to a `Kind`. The default also maps to `.dailyTimeWindow`
    /// since it is the only kind currently defined.
    private static func kindFromRaw(_ raw: String) -> RecurringPattern.Kind {
        switch raw {
        case "dailyTimeWindow": return .dailyTimeWindow
        default: return .dailyTimeWindow
        }
    }
}
