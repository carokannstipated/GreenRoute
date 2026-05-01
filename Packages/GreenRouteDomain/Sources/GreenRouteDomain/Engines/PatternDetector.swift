// Stateless engine that analyses historical inactivity events for recurring daily patterns.

import Foundation

/// Detects whether a set of `InactivityEvent`s cluster around a consistent time of day.
///
/// The detector uses an average-minutes-from-midnight heuristic: it computes the mean
/// start time across all events, then counts how many fall within `toleranceMinutes` of
/// that mean. If enough events match, a `RecurringPattern` is returned.
public struct PatternDetector: Sendable {

    public init() {}

    /// Attempts to find a recurring daily inactivity pattern in `episodes`.
    ///
    /// - Parameters:
    ///   - episodes: Historical inactivity events to analyse.
    ///   - toleranceMinutes: Maximum deviation (in minutes) from the average start time
    ///     that still counts as a match. Defaults to 30 minutes.
    ///   - minimumEvidence: Minimum number of matching episodes required to confirm a pattern.
    ///     Applied twice: once to the full set and once to the filtered matching set.
    ///   - calendar: The calendar used to extract hour and minute components from event dates.
    ///     Pass a UTC calendar in tests for deterministic behaviour.
    /// - Returns: A `RecurringPattern` if the evidence threshold is met, or `nil` otherwise.
    public func detectDailyTimePattern(
        from episodes: [InactivityEvent],
        toleranceMinutes: Int = 30,
        minimumEvidence: Int = 3,
        calendar: Calendar
    ) -> RecurringPattern? {

        guard episodes.count >= minimumEvidence else { return nil }

        // Convert each event's start time to minutes from midnight, discarding the date.
        // This makes the comparison timezone-local and strips day-of-week noise.
        let minutes = episodes.map {
        calendar.component(.hour, from: $0.start) * 60 +
        calendar.component(.minute, from: $0.start)
        }

        let average = minutes.reduce(0, +) / minutes.count

        // Keep only events that start within `toleranceMinutes` of the computed mean.
        let matching = minutes.filter {
            abs($0 - average) <= toleranceMinutes
        }

        guard matching.count >= minimumEvidence else { return nil }

        let window = TimeWindow(
            startMinutes: max(0, average - toleranceMinutes),
            endMinutes: min(1440, average + toleranceMinutes)
        )

        // Confidence is the fraction of all examined episodes that matched, not just
        // the fraction within the window. A high ratio means the pattern is consistent.
        let confidence = Double(matching.count) / Double(episodes.count)

        return RecurringPattern(
            window: window,
            evidenceCount: matching.count,
            confidence: confidence
        )
    }
}
