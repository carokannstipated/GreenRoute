// Tests for PatternDetector — verifies the daily time-window pattern detection logic.

import XCTest
@testable import GreenRouteDomain

final class PatternDetectorTests: XCTestCase {

    /// UTC calendar used throughout so ISO-8601 timestamps map directly to hours/minutes.
    private var calendarUTC: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    // MARK: - Successful detection

    /// Three events clustered around 13:00 UTC (within ±30 min) should produce a pattern
    /// with full confidence (3/3 matching) and a window that contains 13:00.
    func test_detectDailyTimePattern_findsPattern_whenEnoughEvidenceWithinTolerance() throws {
        let detector = PatternDetector()
        let cal = calendarUTC

        let events = [
            makeEvent(date: "2026-02-01T12:55:00Z", durationMinutes: 45),
            makeEvent(date: "2026-02-02T13:05:00Z", durationMinutes: 30),
            makeEvent(date: "2026-02-03T13:00:00Z", durationMinutes: 25)
        ]

        let pattern = detector.detectDailyTimePattern(
            from: events,
            toleranceMinutes: 30,
            minimumEvidence: 3,
            calendar: cal
        )

        let unwrapped = try XCTUnwrap(pattern)
        XCTAssertEqual(unwrapped.evidenceCount, 3)
        XCTAssertEqual(unwrapped.kind, .dailyTimeWindow)
        XCTAssertEqual(unwrapped.confidence, 1.0, accuracy: 0.0001)

        XCTAssertTrue(unwrapped.window.contains(minutesFromMidnight: 13 * 60))
    }

    // MARK: - Insufficient evidence

    /// Two events are below the minimumEvidence threshold of 3 — detector must return nil.
    func test_detectDailyTimePattern_returnsNil_whenNotEnoughEvidence() {
        let detector = PatternDetector()
        let cal = calendarUTC

        let events = [
            makeEvent(date: "2026-02-01T13:00:00Z", durationMinutes: 45),
            makeEvent(date: "2026-02-02T13:05:00Z", durationMinutes: 30)
        ]

        let pattern = detector.detectDailyTimePattern(
            from: events,
            toleranceMinutes: 30,
            minimumEvidence: 3,
            calendar: cal
        )

        XCTAssertNil(pattern)
    }

    // MARK: - Scattered times

    /// Events at 09:00, 13:00, and 18:00 span 9 hours — none of them fall within ±30 min
    /// of the average (~13:20), so fewer than minimumEvidence events match.
    func test_detectDailyTimePattern_returnsNil_whenTimesAreTooScattered() {
        let detector = PatternDetector()
        let cal = calendarUTC

        let events = [
            makeEvent(date: "2026-02-01T09:00:00Z", durationMinutes: 40),
            makeEvent(date: "2026-02-02T13:00:00Z", durationMinutes: 40),
            makeEvent(date: "2026-02-03T18:00:00Z", durationMinutes: 40)
        ]

        let pattern = detector.detectDailyTimePattern(
            from: events,
            toleranceMinutes: 30,
            minimumEvidence: 3,
            calendar: cal
        )

        XCTAssertNil(pattern)
    }
}


private extension PatternDetectorTests {

    /// Creates an `InactivityEvent` starting at the ISO-8601 timestamp and lasting `durationMinutes`.
    func makeEvent(date iso8601: String, durationMinutes: Int) -> InactivityEvent {
        let start = ISO8601DateFormatter().date(from: iso8601)!
        let end = start.addingTimeInterval(TimeInterval(durationMinutes * 60))
        return InactivityEvent(start: start, end: end)
    }
}
