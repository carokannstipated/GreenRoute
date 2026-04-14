//
//  RecommendationMapper.swift
//  GreenRouteData
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import Foundation
import GreenRouteDomain

enum RecommendationMapper {

    static func toEntity(_ model: Recommendation) -> RecommendationEntity {
        RecommendationEntity(
            id: model.id,
            createdAt: model.createdAt,
            triggerRaw: triggerRaw(model.trigger),
            targetId: model.target.id,
            targetName: model.target.name,
            targetLat: model.target.coordinate.latitude,
            targetLon: model.target.coordinate.longitude,
            targetKindRaw: targetKindRaw(model.target.kind),
            distanceMeters: model.distance.value,
            estimatedWalkMinutes: model.estimatedWalkMinutes
        )
    }

    static func toDomain(_ entity: RecommendationEntity) -> Recommendation {
        let target = GreenArea(
            id: entity.targetId,
            name: entity.targetName,
            coordinate: Coordinate(latitude: entity.targetLat, longitude: entity.targetLon),
            kind: kindFromRaw(entity.targetKindRaw)
        )

        return Recommendation(
            id: entity.id,
            createdAt: entity.createdAt,
            trigger: triggerFromRaw(entity.triggerRaw),
            target: target,
            distance: DistanceMeters(value: entity.distanceMeters),
            estimatedWalkMinutes: entity.estimatedWalkMinutes
        )
    }

    // MARK: - Raw mapping

    private static func triggerRaw(_ trigger: Recommendation.Trigger) -> String {
        switch trigger {
        case .userRequested: return "userRequested"
        case .inactivity: return "inactivity"
        case .pattern: return "pattern"
        }
    }

    private static func triggerFromRaw(_ raw: String) -> Recommendation.Trigger {
        switch raw {
        case "pattern": return .pattern
        default: return .inactivity
        }
    }

    private static func targetKindRaw(_ kind: GreenArea.Kind) -> String {
        switch kind {
        case .park: return "park"
        case .forest: return "forest"
        case .natureReserve: return "natureReserve"
        case .beach: return "beach"
        case .other: return "other"
        }
    }

    private static func kindFromRaw(_ raw: String) -> GreenArea.Kind {
        switch raw {
        case "park": return .park
        case "forest": return .forest
        case "natureReserve": return .natureReserve
        case "beach": return .beach
        default: return .other
        }
    }
}
