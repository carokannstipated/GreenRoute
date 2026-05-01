// Fetches recent inactivity history and runs the pattern detector.

import Foundation

/// Queries historical inactivity events and delegates to `PatternDetector` to find
/// a recurring daily pattern. Persists any detected pattern to the repository.
public struct DetectRecurringPatternUseCase: Sendable {

    private let inactivityRepository: InactivityEventRepository
    private let patternRepository: RecurringPatternRepository
    private let detector: PatternDetector

    public init(
        inactivityRepository: InactivityEventRepository,
        patternRepository: RecurringPatternRepository,
        detector: PatternDetector = PatternDetector()
    ) {
        self.inactivityRepository = inactivityRepository
        self.patternRepository = patternRepository
        self.detector = detector
    }

    /// Looks back over recent inactivity events and returns a pattern if one is found.
    ///
    /// - Parameters:
    ///   - now: The reference point in time; the lookback window ends here.
    ///   - lookbackDays: How many days of history to examine. Must be > 0.
    ///   - toleranceMinutes: Tolerance passed to `PatternDetector`; how far from the
    ///     average start time an event may fall and still count as matching.
    ///   - minimumEvidence: Minimum matching events required; forwarded to `PatternDetector`.
    ///   - calendar: Calendar used for date arithmetic and component extraction.
    /// - Returns: The detected `RecurringPattern` (already saved), or `nil` if none found.
    public func execute(
        now: Date,
        lookbackDays: Int = 5,
        toleranceMinutes: Int = 30,
        minimumEvidence: Int = 3,
        calendar: Calendar
    ) async throws -> RecurringPattern? {

        precondition(lookbackDays > 0, "lookbackDays must be > 0")

        // The `?? now` fallback is defensive; calendar subtraction only fails if the
        // date would overflow, which is impossible for a small number of days.
        let start = calendar.date(byAdding: .day, value: -lookbackDays, to: now) ?? now
        let end = now

        let events = try await inactivityRepository.fetch(from: start, to: end)

        guard let pattern = detector.detectDailyTimePattern(
            from: events,
            toleranceMinutes: toleranceMinutes,
            minimumEvidence: minimumEvidence,
            calendar: calendar
        ) else {
            return nil
        }

        try await patternRepository.save(pattern)
        return pattern
    }
}
