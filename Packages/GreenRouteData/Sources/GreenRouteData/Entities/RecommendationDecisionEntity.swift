// SwiftData entity for persisting a RecommendationDecision domain model.

import Foundation
import SwiftData

/// Persistent storage representation of a `RecommendationDecision`.
///
/// The `Decision` enum is stored as a raw `String` because SwiftData does not natively
/// support custom Swift enums. `RecommendationDecisionMapper` handles conversion.
@Model
public final class RecommendationDecisionEntity {

    /// Unique identifier. The `.unique` attribute enforces upsert semantics.
    @Attribute(.unique) public var id: UUID
    /// Foreign-key reference to the associated `RecommendationEntity`.
    public var recommendationID: UUID
    /// Raw string representation of `RecommendationDecision.Decision` (e.g. "accepted", "ignored").
    public var decisionRaw: String
    public var timestamp: Date

    public init(
        id: UUID,
        recommendationID: UUID,
        decisionRaw: String,
        timestamp: Date
    ) {
        self.id = id
        self.recommendationID = recommendationID
        self.decisionRaw = decisionRaw
        self.timestamp = timestamp
    }
}
