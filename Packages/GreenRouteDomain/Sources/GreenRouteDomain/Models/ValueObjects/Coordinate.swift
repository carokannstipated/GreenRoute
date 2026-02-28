//
//  Coordinate.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import Foundation

public struct Coordinate: Equatable, Hashable, Sendable {
    
    public let latitude: Double
    public let longitude: Double
    
    public init(latitude: Double, longitude: Double) {
        precondition((-90.0...90.0).contains(latitude), "Latitude must be between -90 and 90")
        precondition((-180.0...180.0).contains(longitude), "Longitude must be between -180 and 180")
        
        self.latitude = latitude
        self.longitude = longitude
    }
}

public extension Coordinate {
    // Returns distance to another coordinate in meters using the Haversine formula
    
    func distance(to other: Coordinate) -> Double {
        let earthRadius = 6_371_000.0 // meters
        
        let lat1 = latitude.radians
        let lon1 = longitude.radians
        let lat2 = other.latitude.radians
        let lon2 = other.longitude.radians
        
        let dLat = lat2 - lat1
        let dLon = lon2 - lon1
        
        let a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
}

// Private helper for radians value
private extension Double {
    var radians: Double { self * .pi / 180 }
}

