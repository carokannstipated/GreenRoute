// Domain model for a detected recurring inactivity pattern within a daily time window.

import Foundation

/// A repeating pattern of user inactivity that occurs within a consistent time-of-day window.
///
/// Detected by `PatternDetector` from historical `InactivityEvent`s. Once a pattern is
/// confirmed with sufficient evidence it can be used as a proactive trigger for
/// recommendations (see `Recommendation.Trigger.pattern`).
public struct RecurringPattern: Equatable, Hashable, Sendable, Identifiable {

    /// The structural shape of the pattern. Currently only daily time windows are supported.
    public enum Kind: Equatable, Hashable, Sendable {
        /// A window of minutes-from-midnight that repeats every day.
        case dailyTimeWindow
    }

    public let id: UUID

    public let kind: Kind

    /// The time-of-day window during which the pattern is expected to occur.
    public let window: TimeWindow

    /// Number of historical inactivity events that fell within the tolerance window
    /// and contributed to this pattern's detection.
    public let evidenceCount: Int

    /// Fraction of all examined events that matched the window, in the range [0, 1].
    /// Higher values indicate a more consistent daily pattern.
    public let confidence: Double

    public init(id: UUID = UUID(), kind: Kind = .dailyTimeWindow, window: TimeWindow, evidenceCount: Int, confidence: Double) {
        precondition(evidenceCount >= 0, "evidenceCount cannot be negative")
        precondition((0.0...1.0).contains(confidence), "confidence must be between 0 and 1")
        self.id = id
        self.kind = kind
        self.window = window
        self.evidenceCount = evidenceCount
        self.confidence = confidence
    }
}

/// A contiguous time range within a single day, expressed as minutes elapsed since midnight.
///
/// `startMinutes` is inclusive; `endMinutes` is exclusive. The upper bound of `endMinutes`
/// is 1440 (midnight of the following day) to allow windows that end exactly at midnight.
public struct TimeWindow: Equatable, Hashable, Sendable {

    /// Start of the window as minutes from midnight (0–1439).
    public let startMinutes: Int

    /// End of the window as minutes from midnight (1–1440), exclusive.
    public let endMinutes: Int

    public init(startMinutes: Int, endMinutes: Int){
        precondition((0...1439).contains(startMinutes), "startMinutes must be 0...1439")
        precondition((0...1440).contains(endMinutes), "endMinutes must be 0...1440")
        precondition(endMinutes > startMinutes, "endMinutes must be greater than startMinutes")

        self.startMinutes = startMinutes
        self.endMinutes = endMinutes
    }

    /// Returns `true` if `minutesFromMidnight` falls within this window.
    ///
    /// Returns `false` rather than precondition-failing for out-of-range input,
    /// because callers may pass values derived from untrusted time components.
    public func contains(minutesFromMidnight: Int) -> Bool {
        guard (0...1439).contains(minutesFromMidnight) else {return false }
        return minutesFromMidnight >= startMinutes && minutesFromMidnight < endMinutes
    }
}
