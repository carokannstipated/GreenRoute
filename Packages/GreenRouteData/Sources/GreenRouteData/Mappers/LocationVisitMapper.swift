//
//  LocationVisitMapper.swift
//  GreenRouteData
//
//  Created by David Rivera on 03/03/2026.
//

import Foundation
import GreenRouteDomain

enum LocationVisitMapper {
    
    static func toEntity(_ model: LocationVisit) -> LocationVisitEntity {
        LocationVisitEntity(
            id: model.id,
            latitude: model.coordinate.latitude,
            longitude: model.coordinate.longitude,
            arrival: model.arrival,
            departure: model.departure,
            placeCategoryRaw: model.placeCategory.map(placeCategoryRaw)
        )
    }

    static func toDomain(_ entity: LocationVisitEntity) -> LocationVisit {
        LocationVisit(
            id: entity.id,
            coordinate: Coordinate(
                latitude: entity.latitude,
                longitude: entity.longitude
            ),
            arrival: entity.arrival,
            departure: entity.departure,
            placeCategory: entity.placeCategoryRaw.map(placeCategoryFromRaw)
        )
    }
    
    
    // MARK: - Raw Mapping

    private static func placeCategoryRaw(_ category: PlaceCategory) -> String {
        switch category {
        case .home: return "home"
        case .workOrStudy: return "workOrStudy"
        case .other: return "other"
        }
    }
    
    private static func placeCategoryFromRaw(_ raw: String) -> PlaceCategory {
            switch raw {
            case "home": return .home
            case "workOrStudy": return .workOrStudy
            case "other": return .other
            default: return .other
        }
    }
}



    
