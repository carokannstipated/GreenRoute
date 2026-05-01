// Domain model representing a recorded period of user physical inactivity.

import Foundation

/// A closed time interval during which the user was detected as physically inactive.
///
/// Inactivity events are the primary trigger for generating green-break recommendations.
/// The engine compares `duration` against the configured threshold to decide whether
/// the user has been sedentary long enough to warrant a suggestion.
public struct InactivityEvent: Equatable, Hashable, Sendable, Identifiable {

    public let id: UUID

    /// When the inactivity period began.
    public let start: Date

    /// When movement was next detected, ending the inactivity period.
    public let end: Date

    public init(id: UUID = UUID(), start: Date, end: Date) {
        precondition(end >= start, "End date must not be earlier than start date")

        self.id = id
        self.start = start
        self.end = end
    }

    /// Length of the inactivity period in seconds. This is the value compared against
    /// `inactivityThresholdMinutes` in the recommendation engine.
    public var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
}
