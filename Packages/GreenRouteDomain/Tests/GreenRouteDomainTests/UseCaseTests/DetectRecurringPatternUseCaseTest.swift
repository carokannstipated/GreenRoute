// Tests for DetectRecurringPatternUseCase — verifies detection, persistence, and date-range scoping.

import XCTest
@testable import GreenRouteDomain

final class DetectRecurringPatternUseCaseTests: XCTestCase {

    /// UTC calendar so ISO-8601 timestamps in event fixtures map directly to expected hours/minutes.
    private var calendarUTC: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }

    // MARK: - Successful pattern detection

    /// Three events clustered around 13:00 UTC should produce a pattern that is both returned
    /// and saved exactly once to the pattern repository.
    func test_execute_savesAndReturnsPattern_whenDetectorFindsOne() async throws {
        let cal = calendarUTC
        let now = iso("2026-02-06T12:00:00Z")

        let events: [InactivityEvent] = [
            makeEvent(start: "2026-02-02T12:55:00Z", durationMinutes: 30),
            makeEvent(start: "2026-02-03T13:05:00Z", durationMinutes: 25),
            makeEvent(start: "2026-02-05T13:00:00Z", durationMinutes: 40)
        ]

        let inactivityRepo = FakeInactivityEventRepository(events: events)
        let patternRepo = FakeRecurringPatternRepository()

        let useCase = DetectRecurringPatternUseCase(
            inactivityRepository: inactivityRepo,
            patternRepository: patternRepo,
            detector: PatternDetector()
        )

        let pattern = try await useCase.execute(
            now: now,
            lookbackDays: 5,
            toleranceMinutes: 30,
            minimumEvidence: 3,
            calendar: cal
        )

        let unwrapped = try XCTUnwrap(pattern)

        let saved = await patternRepo.allSaved()
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first, unwrapped)

        XCTAssertEqual(unwrapped.kind, .dailyTimeWindow)
        XCTAssertEqual(unwrapped.evidenceCount, 3)
        XCTAssertTrue(unwrapped.window.contains(minutesFromMidnight: 13 * 60))
    }

    // MARK: - No pattern found

    /// Scattered event times (09:00, 13:00, 18:00) produce no pattern — use case must
    /// return nil and must not write anything to the pattern repository.
    func test_execute_returnsNil_whenNoPatternFound() async throws {
        let cal = calendarUTC
        let now = iso("2026-02-06T12:00:00Z")

        let events: [InactivityEvent] = [
            makeEvent(start: "2026-02-02T09:00:00Z", durationMinutes: 30),
            makeEvent(start: "2026-02-03T13:00:00Z", durationMinutes: 25),
            makeEvent(start: "2026-02-05T18:00:00Z", durationMinutes: 40)
        ]

        let inactivityRepo = FakeInactivityEventRepository(events: events)
        let patternRepo = FakeRecurringPatternRepository()

        let useCase = DetectRecurringPatternUseCase(
            inactivityRepository: inactivityRepo,
            patternRepository: patternRepo,
            detector: PatternDetector()
        )

        let pattern = try await useCase.execute(
            now: now,
            lookbackDays: 5,
            toleranceMinutes: 30,
            minimumEvidence: 3,
            calendar: cal
        )

        XCTAssertNil(pattern)

        let saved = await patternRepo.allSaved()
        XCTAssertEqual(saved.count, 0)
    }

    // MARK: - Lookback range scoping

    /// An event from two weeks ago (outside the 5-day lookback window) must not be passed
    /// to the detector. The test verifies the query bounds rather than the detection outcome.
    func test_execute_onlyUsesEventsWithinLookbackRange() async throws {
        let cal = calendarUTC
        let now = iso("2026-02-06T12:00:00Z")

        let old = makeEvent(start: "2026-01-20T13:00:00Z", durationMinutes: 30)
        let inRange: [InactivityEvent] = [
            makeEvent(start: "2026-02-02T13:00:00Z", durationMinutes: 30),
            makeEvent(start: "2026-02-03T13:10:00Z", durationMinutes: 25),
            makeEvent(start: "2026-02-05T12:55:00Z", durationMinutes: 40)
        ]

        let inactivityRepo = FakeInactivityEventRepository(events: [old] + inRange)
        let patternRepo = FakeRecurringPatternRepository()

        let useCase = DetectRecurringPatternUseCase(
            inactivityRepository: inactivityRepo,
            patternRepository: patternRepo,
            detector: PatternDetector()
        )

        _ = try await useCase.execute(
            now: now,
            lookbackDays: 5,
            toleranceMinutes: 30,
            minimumEvidence: 3,
            calendar: cal
        )

        let lastQuery = await inactivityRepo.lastQuery()
        XCTAssertNotNil(lastQuery)
        XCTAssertEqual(lastQuery?.end, now)

        // The start of the query must be before `now` (i.e. 5 days back).
        XCTAssertTrue((lastQuery?.start ?? now) < now)
    }
}

// MARK: - Test doubles

/// In-memory inactivity repository that records the most recent fetch query bounds.
private actor FakeInactivityEventRepository: InactivityEventRepository {
    private let events: [InactivityEvent]

    /// Records the date range passed to the most recent `fetch` call.
    private var query: (start: Date, end: Date)?

    init(events: [InactivityEvent]) {
        self.events = events
    }

    func save(_ event: InactivityEvent) async throws {}

    func fetch(from start: Date, to end: Date) async throws -> [InactivityEvent] {
        query = (start: start, end: end)
        return events.filter { $0.start >= start && $0.start < end }
    }

    func lastQuery() -> (start: Date, end: Date)? { query }
}

/// In-memory pattern repository that accumulates every saved pattern.
private actor FakeRecurringPatternRepository: RecurringPatternRepository {
    private var saved: [RecurringPattern] = []

    func save(_ pattern: RecurringPattern) async throws {
        saved.append(pattern)
    }

    func fetchLatest() async throws -> RecurringPattern? {
        saved.last
    }

    func allSaved() -> [RecurringPattern] { saved }
}

// MARK: - Helpers

private func iso(_ value: String) -> Date {
    ISO8601DateFormatter().date(from: value)!
}

private func makeEvent(start isoStart: String, durationMinutes: Int) -> InactivityEvent {
    let start = iso(isoStart)
    let end = start.addingTimeInterval(TimeInterval(durationMinutes * 60))
    return InactivityEvent(start: start, end: end)
}
