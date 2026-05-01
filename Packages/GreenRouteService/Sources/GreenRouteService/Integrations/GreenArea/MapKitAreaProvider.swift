// Adapts LocalSearching results into GreenArea domain objects, translating
// MapKit POI categories to the GreenArea.Kind enum.

import Foundation
import MapKit
import GreenRouteDomain

/// `GreenAreaProvider` implementation that delegates POI lookup to a `LocalSearching` instance
/// and maps each result to a `GreenArea` domain object.
final class MapKitGreenAreaProvider: GreenAreaProvider, Sendable {

    /// The underlying POI searcher; defaults to the live MapKit implementation.
    private let searcher: LocalSearching

    init(searcher: LocalSearching = MKLocalSearcher()) {
        self.searcher = searcher
    }

    /// Fetches green areas near `coordinate` within `radius` and maps them to domain objects.
    /// The `GreenArea.id` is derived from the place name and coordinates since MapKit does not
    /// provide stable persistent identifiers for POIs.
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

    /// Converts a MapKit POI category to the `GreenArea.Kind` enum.
    /// Unrecognised or nil categories fall through to `.other`.
    private func kind(from category: MKPointOfInterestCategory?) -> GreenArea.Kind {
        switch category {
        case .park:         return .park
        case .beach:        return .beach
        case .nationalPark: return .natureReserve
        default:            return .other
        }
    }
}
