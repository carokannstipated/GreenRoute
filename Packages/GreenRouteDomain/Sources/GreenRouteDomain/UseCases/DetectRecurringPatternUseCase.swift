//
//  DetectRecurringPatternUseCase.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import Foundation

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

    // Detects a recurring daily time pattern from the last N days of inactivity events.
    //
    // - Parameters:
    //   - now: Current time (inject for deterministic testing).
    //   - lookbackDays: How many days to look back (MVP: 5).
    //   - toleranceMinutes: ± window around the central time (MVP: 30).
    //   - minimumEvidence: Minimum matching observations (MVP: 3).
    //   - calendar: Explicit calendar (no `.current` in domain).
    //
    // - Returns: Detected pattern if any, and persists it.
    public func execute(
        now: Date,
        lookbackDays: Int = 5,
        toleranceMinutes: Int = 30,
        minimumEvidence: Int = 3,
        calendar: Calendar
    ) async throws -> RecurringPattern? {

        precondition(lookbackDays > 0, "lookbackDays must be > 0")

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
