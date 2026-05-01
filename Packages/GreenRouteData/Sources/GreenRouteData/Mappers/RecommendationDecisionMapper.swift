// Bidirectional mapper between the RecommendationDecision domain model and its SwiftData entity.

import Foundation
import GreenRouteDomain

/// Translates `RecommendationDecision` ↔ `RecommendationDecisionEntity`,
/// encoding the `Decision` enum as a raw `String`.
enum RecommendationDecisionMapper {

    /// Converts a domain `RecommendationDecision` to a SwiftData entity ready for insertion.
    static func toEntity(_ model: RecommendationDecision) -> RecommendationDecisionEntity {
        RecommendationDecisionEntity(
            id: model.id,
            recommendationID: model.recommendationID,
            decisionRaw: decisionRaw(model.decision),
            timestamp: model.timestamp
        )
    }

    /// Reconstructs a `RecommendationDecision` domain model from a persisted entity.
    static func toDomain(_ entity: RecommendationDecisionEntity) -> RecommendationDecision {
        RecommendationDecision(
            id: entity.id,
            recommendationID: entity.recommendationID,
            decision: decisionFromRaw(entity.decisionRaw),
            timestamp: entity.timestamp
        )
    }

    /// Encodes a `Decision` to its canonical string representation.
    private static func decisionRaw(_ decision: RecommendationDecision.Decision) -> String {
        switch decision {
        case .accepted: return "accepted"
        case .dismissed: return "dismissed"
        case .ignored: return "ignored"
        }
    }

    /// Decodes a raw string to a `Decision`. Any unrecognised value maps to `.ignored`
    /// as the safest default (no destructive user action is implied).
    private static func decisionFromRaw(_ raw: String) -> RecommendationDecision.Decision {
        switch raw {
        case "accepted": return .accepted
        case "dismissed": return .dismissed
        case "ignored": return .ignored
        default: return .ignored
        }
    }
}