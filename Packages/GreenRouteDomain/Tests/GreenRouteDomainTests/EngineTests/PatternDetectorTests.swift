//
//  PatternDetectorTests.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import XCTest
@testable import GreenRouteDomain

final class PatternDetectorTests: XCTestCase {

    private var calendarUTC: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    func test_detectDailyTimePattern_findsPattern_whenEnoughEvidenceWithinTolerance() throws {
        let detector = PatternDetector()
        let cal = calendarUTC

        // 2026-02-01..03 at ~13:00 ± 10 min
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

        // Average is around 13:00 => 780; window should contain 780
        XCTAssertTrue(unwrapped.window.contains(minutesFromMidnight: 13 * 60))
    }

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

// MARK: - Helpers

private extension PatternDetectorTests {

    func makeEvent(date iso8601: String, durationMinutes: Int) -> InactivityEvent {
        let start = ISO8601DateFormatter().date(from: iso8601)!
        let end = start.addingTimeInterval(TimeInterval(durationMinutes * 60))
        return InactivityEvent(start: start, end: end)
    }
}
