//
//  LocationVisit.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import Foundation

public enum PlaceCategory: Equatable, Hashable, Sendable {
    case home
    case workOrStudy
    case other
}

public struct LocationVisit: Equatable, Hashable, Sendable, Identifiable {
    
    public let id: UUID
    
    // Representative coordinate for the visit (e.g. centroid)
    public let coordinate: Coordinate
    public let arrival: Date
    public let departure: Date?
    
    // Optional classification (can be set by domain logic later)
    public var placeCategory: PlaceCategory?
    
    public init(id: UUID = UUID(), coordinate: Coordinate, arrival: Date, departure: Date?, placeCategory: PlaceCategory? = nil) {
        
        if let departure {
            precondition(departure >= arrival, "Departure must not be earlier than arrival")
        }
        self.id = id
        self.coordinate = coordinate
        self.arrival = arrival
        self.departure = departure
        self.placeCategory = placeCategory
    }
    
    public var isOngoing: Bool { departure == nil }
    
    public var duration: TimeInterval? {
        guard let departure else { return nil }
        return departure.timeIntervalSince(arrival)
    }
}
