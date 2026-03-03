//
//  InactivityEventMapper.swift
//  GreenRouteData
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import Foundation
import GreenRouteDomain

enum InactivityEventMapper {
    static func toEntity(_ model: InactivityEvent) -> InactivityEventEntity {
        InactivityEventEntity(id: model.id, start: model.start, end: model.end)
    }

    static func toDomain(_ entity: InactivityEventEntity) -> InactivityEvent {
        InactivityEvent(id: entity.id, start: entity.start, end: entity.end)
    }
}
