// Unit tests for InactivityMonitor.handleActivities(_:windowStart:windowEnd:).
// Tests cover emission correctness, non-emission on movement, empty-input handling,
// and the deduplication logic that prevents back-to-back events within the threshold.

import XCTest
@testable import GreenRouteService

final class InactivityMonitorTests: XCTestCase {

    // MARK: - Event emission

    /// Verifies that a window containing only stationary activities causes exactly one
    /// `inactivityDetected` event with the correct start and end timestamps.
    func test_handleActivities_allStationary_emitsEvent() async throws {
        let emitted = EventCollector()
        let monitor = makeMonitor { event in Task { await emitted.append(event) } }

        let windowStart = Date(timeIntervalSince1970: 0)
        let windowEnd = Date(timeIntervalSince1970: 20 * 60)
        let activities: [MotionActivity] = [.stationaryOnly, .stationaryOnly]

        await monitor.handleActivities(activities, windowStart: windowStart, windowEnd: windowEnd)
        try await Task.sleep(for: .milliseconds(20))

        let events = await emitted.events
        XCTAssertEqual(events.count, 1)
        guard case .inactivityDetected(let event) = events[0] else {
            return XCTFail("Expected inactivityDetected")
        }
        XCTAssertEqual(event.start, windowStart)
        XCTAssertEqual(event.end, windowEnd)
    }

    /// Verifies that a window containing at least one moving activity produces no event,
    /// even when other activities in the same window are stationary.
    func test_handleActivities_hasMovingActivity_doesNotEmit() async throws {
        let emitted = EventCollector()
        let monitor = makeMonitor { event in Task { await emitted.append(event) } }

        let activities: [MotionActivity] = [.stationaryOnly, .walking]
        await monitor.handleActivities(activities, windowStart: Date(), windowEnd: Date())
        try await Task.sleep(for: .milliseconds(20))

        let count = await emitted.count
        XCTAssertEqual(count, 0)
    }

    /// Verifies that an empty activity array produces no event, since no data cannot
    /// be interpreted as confirmed stationary behaviour.
    func test_handleActivities_emptyActivities_doesNotEmit() async throws {
        let emitted = EventCollector()
        let monitor = makeMonitor { event in Task { await emitted.append(event) } }

        await monitor.handleActivities([], windowStart: Date(), windowEnd: Date())
        try await Task.sleep(for: .milliseconds(20))

        let count = await emitted.count
        XCTAssertEqual(count, 0)
    }

    // MARK: - Deduplication

    /// Verifies that a second stationary window whose end timestamp falls within
    /// `inactivityThreshold` of the first emission does not produce a second event.
    /// This prevents the monitor from flooding the system with repeated inactivity alerts
    /// for the same sedentary period.
    func test_handleActivities_doesNotEmitDuplicateWithinThreshold() async throws {
        let emitted = EventCollector()
        let monitor = makeMonitor(threshold: 60 * 60) { event in Task { await emitted.append(event) } }

        let t0  = Date(timeIntervalSince1970: 0)
        let t20 = Date(timeIntervalSince1970: 20 * 60)
        let t40 = Date(timeIntervalSince1970: 40 * 60)
        let activities: [MotionActivity] = [.stationaryOnly]

        await monitor.handleActivities(activities, windowStart: t0, windowEnd: t20)
        try await Task.sleep(for: .milliseconds(20))
        let firstCount = await emitted.count
        XCTAssertEqual(firstCount, 1)

        // Second window ends only 40 min after first — still within the 60 min threshold.
        await monitor.handleActivities(activities, windowStart: t20, windowEnd: t40)
        try await Task.sleep(for: .milliseconds(20))
        let secondCount = await emitted.count
        XCTAssertEqual(secondCount, 1)
    }

    /// Verifies that a second stationary window whose end falls beyond `inactivityThreshold`
    /// after the first emission does produce a new event, confirming deduplication resets correctly.
    func test_handleActivities_emitsAgainAfterThreshold() async throws {
        let emitted = EventCollector()
        let monitor = makeMonitor(threshold: 30 * 60) { event in Task { await emitted.append(event) } }

        let t0  = Date(timeIntervalSince1970: 0)
        let t20 = Date(timeIntervalSince1970: 20 * 60)
        let t60 = Date(timeIntervalSince1970: 60 * 60)
        let t80 = Date(timeIntervalSince1970: 80 * 60)
        let activities: [MotionActivity] = [.stationaryOnly]

        await monitor.handleActivities(activities, windowStart: t0, windowEnd: t20)
        try await Task.sleep(for: .milliseconds(20))
        let firstCount = await emitted.count
        XCTAssertEqual(firstCount, 1)

        // Second window ends 60 min after the first — exceeds the 30 min threshold.
        await monitor.handleActivities(activities, windowStart: t60, windowEnd: t80)
        try await Task.sleep(for: .milliseconds(20))
        let secondCount = await emitted.count
        XCTAssertEqual(secondCount, 2)
    }

    // MARK: - Helpers

    private func makeMonitor(
        threshold: TimeInterval = 20 * 60,
        emit: @escaping @Sendable (ServiceEvent) -> Void
    ) -> InactivityMonitor {
        InactivityMonitor(
            motion: FakeMotionClient(),
            clock: FakeClock(current: Date()),
            config: .init(inactivityThreshold: threshold),
            emit: emit
        )
    }
}

/// Thread-safe event collector used across test suites to accumulate emitted `ServiceEvent` values.
actor EventCollector {
    private(set) var events: [ServiceEvent] = []
    var count: Int { events.count }
    func append(_ event: ServiceEvent) { events.append(event) }
}
