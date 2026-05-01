// Defines the LocalSearching protocol and the LocalSearchResult value type used
// to decouple MapKit POI search from the green area provider logic.

import Foundation
import MapKit
import GreenRouteDomain

/// Abstracts MapKit local search to allow substitution with test doubles.
/// Implementations query points of interest near a coordinate within a given radius.
protocol LocalSearching: Sendable {
    /// Searches for points of interest near `coordinate` within `radius`.
    /// - Returns: An array of raw search results; may be empty if no matching places are found.
    /// - Throws: Any networking or MapKit error encountered during the search.
    func search(near coordinate: Coordinate, radius: DistanceMeters) async throws -> [LocalSearchResult]
}

/// A raw point-of-interest result returned by a `LocalSearching` implementation.
/// Carries the minimum data needed to construct a `GreenArea` domain object.
struct LocalSearchResult: Sendable {
    let name: String
    let latitude: Double
    let longitude: Double
    /// The MapKit category for the place; nil when MapKit does not provide one.
    let pointOfInterestCategory: MKPointOfInterestCategory?
}
