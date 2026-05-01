// Bidirectional mapper between the GreenArea domain model and its SwiftData entity.

import Foundation
import GreenRouteDomain

/// Translates `GreenArea` ↔ `GreenAreaEntity`, handling the `Kind` enum / raw-string encoding.
enum GreenAreaMapper {

    /// Converts a domain `GreenArea` to a SwiftData entity ready for insertion.
    static func toEntity(_ model: GreenArea) -> GreenAreaEntity {
        GreenAreaEntity(
            id: model.id,
            name: model.name,
            latitude: model.coordinate.latitude,
            longitude: model.coordinate.longitude,
            kindRaw: kindRaw(model.kind)
        )
    }

    /// Reconstructs a `GreenArea` domain model from a persisted entity.
    static func toDomain(_ entity: GreenAreaEntity) -> GreenArea {
        GreenArea(
            id: entity.id,
            name: entity.name,
            coordinate: Coordinate(
                latitude: entity.latitude,
                longitude: entity.longitude
            ),
            kind: kindFromRaw(entity.kindRaw)
        )
    }

    /// Encodes a `Kind` to its canonical string representation stored in the database.
    private static func kindRaw(_ kind: GreenArea.Kind) -> String {
        switch kind {
        case .park: return "park"
        case .forest: return "forest"
        case .natureReserve: return "natureReserve"
        case .beach: return "beach"
        case .other: return "other"
        }
    }

    /// Decodes a raw string to a `Kind`. Any unrecognised value maps to `.other` so that
    /// future kind values added by a newer app version do not crash an older install on read.
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
