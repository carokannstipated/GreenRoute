//
//  MKLocalSearching.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//

import Foundation
import MapKit
import GreenRouteDomain

final class MKLocalSearcher: LocalSearching, Sendable {

    private static let greenCategories: [MKPointOfInterestCategory] = [
        .park, .beach, .nationalPark
    ]

    func search(near coordinate: Coordinate, radius: DistanceMeters) async throws -> [LocalSearchResult] {
        let center = CLLocationCoordinate2D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        let region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: radius.value * 2,
            longitudinalMeters: radius.value * 2
        )

        let request = MKLocalSearch.Request()
        request.region = region
        request.resultTypes = .pointOfInterest
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: Self.greenCategories)

        let response = try await MKLocalSearch(request: request).start()

        return response.mapItems.compactMap { item in
            guard let name = item.name else { return nil }
            return LocalSearchResult(
                name: name,
                latitude: item.placemark.coordinate.latitude,
                longitude: item.placemark.coordinate.longitude,
                pointOfInterestCategory: item.pointOfInterestCategory
            )
        }
    }
}
