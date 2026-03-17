//
//  LocalSearching.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//

import Foundation
import MapKit
import GreenRouteDomain

protocol LocalSearching: Sendable {
    func search(near coordinate: Coordinate, radius: DistanceMeters) async throws -> [LocalSearchResult]
}

struct LocalSearchResult: Sendable {
    let name: String
    let latitude: Double
    let longitude: Double
    let pointOfInterestCategory: MKPointOfInterestCategory?
}
