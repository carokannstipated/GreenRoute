// MapKit-backed implementation of LocalSearching that queries parks, beaches,
// and national parks near a given coordinate.

import Foundation
import MapKit
import GreenRouteDomain

/// Performs `MKLocalSearch` requests filtered to green/natural POI categories.
final class MKLocalSearcher: LocalSearching, Sendable {

    /// The subset of MapKit POI categories considered "green" spaces for this app.
    private static let greenCategories: [MKPointOfInterestCategory] = [
        .park, .beach, .nationalPark
    ]

    /// Searches MapKit for green-space POIs near the given coordinate.
    /// The search region is a square with side length `radius * 2` centred on `coordinate`.
    /// Results with no name are silently discarded.
    func search(near coordinate: Coordinate, radius: DistanceMeters) async throws -> [LocalSearchResult] {
        let center = CLLocationCoordinate2D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        // Build a region whose diameter equals the requested radius in both axes.
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
