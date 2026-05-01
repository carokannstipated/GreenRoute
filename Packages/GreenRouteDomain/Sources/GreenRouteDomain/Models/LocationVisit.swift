// Domain model for a detected stay at a geographic location.

import Foundation

/// Classifies a location visit by the type of place where it occurred.
///
/// Used to filter visits so that inactivity at home or work is handled differently
/// from inactivity in other contexts (e.g. a café or transit stop).
public enum PlaceCategory: Equatable, Hashable, Sendable {
    case home
    case workOrStudy
    case other
}

/// A detected stay at a specific geographic location, with optional place classification.
///
/// Visits are recorded continuously; a `departure` of `nil` means the visit is still in progress.
public struct LocationVisit: Equatable, Hashable, Sendable, Identifiable {

    public let id: UUID

    /// The geographic location where the visit took place.
    public let coordinate: Coordinate

    /// When the user arrived at the location.
    public let arrival: Date

    /// When the user left the location. `nil` for a visit that has not yet ended.
    public let departure: Date?

    /// The classified type of place, if known. `nil` when no match could be determined.
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

    /// `true` when the user has not yet left this location.
    public var isOngoing: Bool { departure == nil }

    /// Duration of the visit in seconds. Returns `nil` for ongoing visits where
    /// no departure has been recorded yet.
    public var duration: TimeInterval? {
        guard let departure else { return nil }
        return departure.timeIntervalSince(arrival)
    }
}
