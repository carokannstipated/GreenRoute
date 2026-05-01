// A user-saved named location used to classify home and work visits.

import Foundation

/// A named geographic location that the user has explicitly saved (e.g. home or work).
///
/// `SavedAddress` is `Codable` so it can be persisted to `UserDefaults` via `JSONEncoder`.
public struct SavedAddress: Equatable, Hashable, Sendable, Codable {

    /// Human-readable label shown in the UI (e.g. "Home", "DTU Campus").
    public let displayName: String

    /// The geographic coordinate of the address.
    public let coordinate: Coordinate

    public init(displayName: String, coordinate: Coordinate) {
        precondition(
            !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            "SavedAddress displayName must not be empty"
        )
        self.displayName = displayName
        self.coordinate = coordinate
    }
}
