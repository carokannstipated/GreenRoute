// Geographic coordinate value object and Haversine great-circle distance calculation.

import Foundation

/// An immutable WGS-84 geographic coordinate.
///
/// Enforces valid ranges at init time: latitude ∈ [−90, 90], longitude ∈ [−180, 180].
public struct Coordinate: Equatable, Hashable, Sendable, Codable {

    /// Decimal degrees north of the equator (negative = south).
    public let latitude: Double

    /// Decimal degrees east of the prime meridian (negative = west).
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        precondition((-90.0...90.0).contains(latitude), "Latitude must be between -90 and 90")
        precondition((-180.0...180.0).contains(longitude), "Longitude must be between -180 and 180")

        self.latitude = latitude
        self.longitude = longitude
    }
}

public extension Coordinate {

    /// Returns the straight-line (great-circle) distance to `other`, in metres.
    ///
    /// Uses the Haversine formula with an Earth mean radius of 6 371 000 m, which
    /// gives sub-percent accuracy for the short urban distances relevant to this app.
    func distance(to other: Coordinate) -> Double {
        let earthRadius = 6_371_000.0

        let lat1 = latitude.radians
        let lon1 = longitude.radians
        let lat2 = other.latitude.radians
        let lon2 = other.longitude.radians

        let dLat = lat2 - lat1
        let dLon = lon2 - lon1

        // Haversine intermediate value — the square of half the chord length.
        let a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)

        // Angular distance in radians.
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return earthRadius * c
    }
}

private extension Double {
    /// Converts a value in decimal degrees to radians.
    var radians: Double { self * .pi / 180 }
}
