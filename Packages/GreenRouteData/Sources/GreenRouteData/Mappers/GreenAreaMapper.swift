//
//  GreenAreaMapper.swift
//  GreenRouteDomain
//
//  Created by David Rivera on 17/03/2026.
//

import Foundation
import GreenRouteDomain

enum GreenAreaMapper {

    static func toEntity(_ model: GreenArea) -> GreenAreaEntity {
        GreenAreaEntity(
            id: model.id,
            name: model.name,
            latitude: model.coordinate.latitude,
            longitude: model.coordinate.longitude,
            kindRaw: kindRaw(model.kind)
        )
    }

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

    private static func kindRaw(_ kind: GreenArea.Kind) -> String {
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
