// SwiftData entity for persisting a LocationVisit domain model.

import Foundation
import SwiftData

/// Persistent storage representation of a `LocationVisit`.
///
/// Coordinate fields are stored as flat `Double`s because SwiftData cannot persist
/// custom nested value types like `Coordinate`. `LocationVisitMapper` reconstructs
/// the `Coordinate` on read.
@Model
public final class LocationVisitEntity {

    /// Unique identifier. The `.unique` attribute enforces upsert semantics.
    @Attribute(.unique) public var id: UUID

    /// Flat storage for the visit coordinate (latitude component).
    public var latitude: Double
    /// Flat storage for the visit coordinate (longitude component).
    public var longitude: Double

    public var arrival: Date
    /// `nil` when the visit has not yet ended (i.e. the user is still at this location).
    public var departure: Date?

    /// Raw string representation of `PlaceCategory`, or `nil` if the category is unknown.
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
