// Domain model representing an outdoor green space that can be recommended as a break destination.

import Foundation

/// An outdoor green space (park, forest, beach, etc.) that the recommendation engine
/// can suggest as a destination for a short walking break.
public struct GreenArea: Equatable, Hashable, Sendable, Identifiable {

    /// Classifies the type of green space for display and filtering purposes.
    public enum Kind: Equatable, Hashable, Sendable {
        case park
        case forest
        case natureReserve
        case beach
        case other
    }

    /// Stable, unique identifier (typically sourced from an external map API).
    public let id: String

    /// Human-readable display name shown in notifications and the UI.
    public let name: String

    /// Geographic centre of the green area, used for distance calculations.
    public let coordinate: Coordinate

    /// Category of the green space; defaults to `.other` when the type is unknown.
    public let kind: Kind

    public init(id: String, name: String, coordinate: Coordinate, kind: Kind = .other) {
        precondition(!id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "GreenArea id must not be empty")
        precondition(!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "GreenArea name must not be empty")
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.kind = kind
    }
}
