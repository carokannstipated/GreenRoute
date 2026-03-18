//
//  LocationVisitEntity.swift
//  GreenRouteData
//
//  Created by David Rivera on 03/03/2026.
//

import Foundation
import SwiftData

@Model
public final class LocationVisitEntity {
    
    @Attribute(.unique) public var id: UUID
    
    // Stored as primitives (SwiftData-friendly)
    public var latitude: Double
    public var longitude: Double
    
    public var arrival: Date
    public var departure: Date?
    
    // Persist raw value representation
    public var placeCategoryRaw: String?
    
    public init(
        id: UUID,
        latitude: Double,
        longitude: Double,
        arrival: Date,
        departure: Date?,
        placeCategoryRaw: String?
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.arrival = arrival
        self.departure = departure
        self.placeCategoryRaw = placeCategoryRaw
    }
}
