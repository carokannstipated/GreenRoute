// Type-safe wrapper for distances expressed in metres.

import Foundation

/// A non-negative distance in metres.
///
/// Wrapping the raw `Double` in a dedicated type prevents accidental mixing of
/// distances with other scalar values and makes units self-documenting at call sites.
public struct DistanceMeters: Equatable, Hashable, Sendable {

    /// The distance in metres. Always ≥ 0.
    public let value: Double

    public init(value: Double) {
        precondition(value >= 0, "Distance cannot be negative")
        self.value = value
    }
}

extension DistanceMeters: Comparable {
    public static func < (lhs: DistanceMeters, rhs: DistanceMeters) -> Bool {
        lhs.value < rhs.value
    }
}
