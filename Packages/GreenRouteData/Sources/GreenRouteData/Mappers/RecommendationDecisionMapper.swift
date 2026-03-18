//
//  RecommendationDecisionMapper.swift
//  GreenRouteData
//
//  Created by David Rivera on 17/03/2026.
//


import Foundation
import GreenRouteDomain

enum RecommendationDecisionMapper {

    static func toEntity(_ model: RecommendationDecision) -> RecommendationDecisionEntity {
        RecommendationDecisionEntity(
            id: model.id,
            recommendationID: model.recommendationID,
            decisionRaw: decisionRaw(model.decision),
            timestamp: model.timestamp
        )
    }

    static func toDomain(_ entity: RecommendationDecisionEntity) -> RecommendationDecision {
        RecommendationDecision(
            id: entity.id,
            recommendationID: entity.recommendationID,
            decision: decisionFromRaw(entity.decisionRaw),
            timestamp: entity.timestamp
        )
    }

    private static func decisionRaw(_ decision: RecommendationDecision.Decision) -> String {
        switch decision {
        case .accepted: return "accepted"
        case .dismissed: return "dismissed"
        case .ignored: return "ignored"
        }
    }

    private static func decisionFromRaw(_ raw: String) -> RecommendationDecision.Decision {
        switch raw {
        case "accepted": return .accepted
        case "dismissed": return .dismissed
        case "ignored": return .ignored
        default: return .ignored
        }
    }
}