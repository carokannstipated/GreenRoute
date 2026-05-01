// A generated suggestion to walk to a nearby green area for a short break.

import Foundation

/// A concrete suggestion produced by the recommendation engine, pointing the user
/// towards a specific nearby green area.
public struct Recommendation: Equatable, Hashable, Sendable, Identifiable {

    /// The event that caused this recommendation to be generated.
    public enum Trigger: Equatable, Hashable, Sendable {
        /// The user has been inactive for longer than the configured threshold.
        case inactivity
        /// A recurring inactivity pattern was detected at this time of day.
        case pattern
        /// The user explicitly requested a recommendation.
        case userRequested
    }

    public let id: UUID

    /// When the recommendation was created; used to scope history queries.
    public let createdAt: Date

    /// What caused this recommendation to be generated.
    public let trigger: Trigger

    /// The green area the user is being recommended to visit.
    public let target: GreenArea

    /// Straight-line distance from the user's current position to `target`.
    public let distance: DistanceMeters

    /// Estimated walking time to `target` in minutes.
    /// Always ≥ 1 when `distance > 0`, so notifications never say "0 min walk".
    public let estimatedWalkMinutes: Int

    public init(id: UUID = UUID(), createdAt: Date, trigger: Trigger, target: GreenArea, distance: DistanceMeters, estimatedWalkMinutes: Int) {
        precondition(estimatedWalkMinutes >= 0, "estimatedWalkMinutes cannot be negative")
        self.id = id
        self.createdAt = createdAt
        self.trigger = trigger
        self.target = target
        self.distance = distance
        self.estimatedWalkMinutes = estimatedWalkMinutes
    }
}
