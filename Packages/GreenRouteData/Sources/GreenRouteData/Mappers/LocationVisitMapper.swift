// Bidirectional mapper between the LocationVisit domain model and its SwiftData entity.

import Foundation
import GreenRouteDomain

/// Translates `LocationVisit` ↔ `LocationVisitEntity`, handling coordinate flattening
/// and `PlaceCategory` raw-string encoding.
enum LocationVisitMapper {

    /// Converts a domain `LocationVisit` to a SwiftData entity ready for insertion.
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

    /// Reconstructs a `LocationVisit` domain model from a persisted entity,
    /// reassembling the `Coordinate` from flat latitude/longitude fields.
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

    /// Encodes a `PlaceCategory` to its canonical string representation.
    private static func placeCategoryRaw(_ category: PlaceCategory) -> String {
        switch category {
        case .home: return "home"
        case .workOrStudy: return "workOrStudy"
        case .other: return "other"
        }
    }

    /// Decodes a raw string to a `PlaceCategory`. Any unrecognised value maps to `.other`.
    private static func placeCategoryFromRaw(_ raw: String) -> PlaceCategory {
            switch raw {
            case "home": return .home
            case "workOrStudy": return .workOrStudy
            case "other": return .other
            default: return .other
        }
    }
}



    
