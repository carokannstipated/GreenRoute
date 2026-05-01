// Bidirectional mapper between the Recommendation domain model and its SwiftData entity.

import Foundation
import GreenRouteDomain

/// Translates `Recommendation` ↔ `RecommendationEntity`, denormalising the embedded
/// `GreenArea` target into flat entity fields and encoding enums as raw strings.
enum RecommendationMapper {

    /// Converts a domain `Recommendation` to a SwiftData entity.
    /// The target `GreenArea` is spread across the flat `target*` entity fields.
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

    /// Reconstructs a `Recommendation` domain model from a persisted entity,
    /// reassembling the nested `GreenArea` from the flat target fields.
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

    /// Encodes a `Trigger` to its canonical string representation.
    private static func triggerRaw(_ trigger: Recommendation.Trigger) -> String {
        switch trigger {
        case .userRequested: return "userRequested"
        case .inactivity: return "inactivity"
        case .pattern: return "pattern"
        }
    }

    /// Decodes a raw string to a `Trigger`. "pattern" is mapped explicitly;
    /// "userRequested" and any unrecognised value fall back to `.inactivity`.
    private static func triggerFromRaw(_ raw: String) -> Recommendation.Trigger {
        switch raw {
        case "pattern": return .pattern
        default: return .inactivity
        }
    }

    /// Encodes a `GreenArea.Kind` for the target field.
    private static func targetKindRaw(_ kind: GreenArea.Kind) -> String {
        switch kind {
        case .park: return "park"
        case .forest: return "forest"
        case .natureReserve: return "natureReserve"
        case .beach: return "beach"
        case .other: return "other"
        }
    }

    /// Decodes a raw string to a `GreenArea.Kind`. Any unrecognised value maps to `.other`.
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
