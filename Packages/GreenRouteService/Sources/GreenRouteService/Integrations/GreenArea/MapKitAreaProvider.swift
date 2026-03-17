//
//  MapKitAreaProvicer.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//

import Foundation
import MapKit
import GreenRouteDomain

final class MapKitGreenAreaProvider: GreenAreaProvider, Sendable {

    private let searcher: LocalSearching

    init(searcher: LocalSearching = MKLocalSearcher()) {
        self.searcher = searcher
    }

    func fetchGreenAreas(near coordinate: Coordinate, radius: DistanceMeters) async throws -> [GreenArea] {
        let results = try await searcher.search(near: coordinate, radius: radius)
        return results.map { result in
            GreenArea(
                id: "\(result.name)_\(result.latitude)_\(result.longitude)",
                name: result.name,
                coordinate: Coordinate(latitude: result.latitude, longitude: result.longitude),
                kind: kind(from: result.pointOfInterestCategory)
            )
        }
    }

    private func kind(from category: MKPointOfInterestCategory?) -> GreenArea.Kind {
        switch category {
        case .park:         return .park
        case .beach:        return .beach
        case .nationalPark: return .natureReserve
        default:            return .other
        }
    }
}
