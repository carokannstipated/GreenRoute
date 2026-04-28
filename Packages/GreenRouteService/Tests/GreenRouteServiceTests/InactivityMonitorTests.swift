//
//  InactivityMonitorTests.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 03/03/2026.
//

import XCTest
@testable import GreenRouteService

final class InactivityMonitorTests: XCTestCase {

    func test_handleActivities_allStationary_emitsEvent() async throws {
        let emitted = EventCollector()
        let monitor = makeMonitor { event in Task { await emitted.append(event) } }

        let windowStart = Date(timeIntervalSince1970: 0)
        let windowEnd = Date(timeIntervalSince1970: 20 * 60)
        let activities = [.stationaryOnly, .stationaryOnly]

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

    func test_handleActivities_hasMovingActivity_doesNotEmit() async throws {
        let emitted = EventCollector()
        let monitor = makeMonitor { event in Task { await emitted.append(event) } }

        let activities = [.stationaryOnly, .walking]
        await monitor.handleActivities(activities, windowStart: Date(), windowEnd: Date())
        try await Task.sleep(for: .milliseconds(20))

        XCTAssertEqual(await emitted.count, 0)
    }

    func test_handleActivities_emptyActivities_doesNotEmit() async throws {
        let emitted = EventCollector()
        let monitor = makeMonitor { event in Task { await emitted.append(event) } }

        await monitor.handleActivities([], windowStart: Date(), windowEnd: Date())
        try await Task.sleep(for: .milliseconds(20))

        XCTAssertEqual(await emitted.count, 0)
    }

    func test_handleActivities_doesNotEmitDuplicateWithinThreshold() async throws {
        let emitted = EventCollector()
        let monitor = makeMonitor(threshold: 60 * 60) { event in Task { await emitted.append(event) } }

        let t0  = Date(timeIntervalSince1970: 0)
        let t20 = Date(timeIntervalSince1970: 20 * 60)
        let t40 = Date(timeIntervalSince1970: 40 * 60)
        let activities = [.stationaryOnly]

        await monitor.handleActivities(activities, windowStart: t0, windowEnd: t20)
        try await Task.sleep(for: .milliseconds(20))
        XCTAssertEqual(await emitted.count, 1)

        // 40 min after first window end — still within 60 min threshold
        await monitor.handleActivities(activities, windowStart: t20, windowEnd: t40)
        try await Task.sleep(for: .milliseconds(20))
        XCTAssertEqual(await emitted.count, 1)
    }

    func test_handleActivities_emitsAgainAfterThreshold() async throws {
        let emitted = EventCollector()
        let monitor = makeMonitor(threshold: 30 * 60) { event in Task { await emitted.append(event) } }

        let t0  = Date(timeIntervalSince1970: 0)
        let t20 = Date(timeIntervalSince1970: 20 * 60)
        let t60 = Date(timeIntervalSince1970: 60 * 60)
        let t80 = Date(timeIntervalSince1970: 80 * 60)
        let activities = [.stationaryOnly]

        await monitor.handleActivities(activities, windowStart: t0, windowEnd: t20)
        try await Task.sleep(for: .milliseconds(20))
        XCTAssertEqual(await emitted.count, 1)

        // 40 min gap since last window end — exceeds 30 min threshold
        await monitor.handleActivities(activities, windowStart: t60, windowEnd: t80)
        try await Task.sleep(for: .milliseconds(20))
        XCTAssertEqual(await emitted.count, 2)
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

actor EventCollector {
    private(set) var events: [ServiceEvent] = []
    var count: Int { events.count }
    func append(_ event: ServiceEvent) { events.append(event) }
}
