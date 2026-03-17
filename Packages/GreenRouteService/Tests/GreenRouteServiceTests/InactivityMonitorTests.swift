//
//  InactivityMonitorTests.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 03/03/2026.
//

import XCTest
@testable import GreenRouteService

final class InactivityMonitorTests: XCTestCase {

    func test_emitsEventAfterThreshold() async {
        let motion = FakeMotionClient()
        let clock = FakeClock(current: Date(timeIntervalSince1970: 0))

        let emitted = EventCollector()

        let monitor = InactivityMonitor(
            motion: motion,
            clock: clock,
            config: .init(inactivityThreshold: 60),
            emit: { event in
                Task { await emitted.append(event) }
            }
        )

        await monitor.start()

        // t=0 stationary -> maybeInactive
        motion.push(.stationaryOnly)
        try? await Task.sleep(for: .milliseconds(10)) // Allow async processing
        await XCTAssertEqualAsync(await emitted.count, 0)

        // t=59 stationary -> still no event
        clock.current = Date(timeIntervalSince1970: 59)
        motion.push(.stationaryOnly)
        try? await Task.sleep(for: .milliseconds(10))
        await XCTAssertEqualAsync(await emitted.count, 0)

        // t=60 stationary -> emit
        clock.current = Date(timeIntervalSince1970: 60)
        motion.push(.stationaryOnly)
        try? await Task.sleep(for: .milliseconds(10))

        let events = await emitted.events
        XCTAssertEqual(events.count, 1)
        // (valgfrit) assert case type:
        if case .inactivityDetected = events[0] {
            // ok
        } else {
            XCTFail("Expected inactivityDetected")
        }
    }

    func test_doesNotEmitAgainWhileStillInactive() async {
        let motion = FakeMotionClient()
        let clock = FakeClock(current: Date(timeIntervalSince1970: 0))

        let emitted = EventCollector()

        let monitor = InactivityMonitor(
            motion: motion,
            clock: clock,
            config: .init(inactivityThreshold: 60),
            emit: { event in
                Task { await emitted.append(event) }
            }
        )

        await monitor.start()

        motion.push(.stationaryOnly)
        try? await Task.sleep(for: .milliseconds(10))  // Wait for first push to process
        clock.current = Date(timeIntervalSince1970: 60)
        motion.push(.stationaryOnly)
        try? await Task.sleep(for: .milliseconds(10))
        await XCTAssertEqualAsync(await emitted.count, 1)

        // still stationary later -> should NOT emit again
        clock.current = Date(timeIntervalSince1970: 120)
        motion.push(.stationaryOnly)
        try? await Task.sleep(for: .milliseconds(10))
        await XCTAssertEqualAsync(await emitted.count, 1)

        // walking resets -> can emit again later
        motion.push(.walking)
        try? await Task.sleep(for: .milliseconds(10))  // Wait for walking state to process
        clock.current = Date(timeIntervalSince1970: 121)
        motion.push(.stationaryOnly)
        try? await Task.sleep(for: .milliseconds(10))  // Wait for stationary to process
        clock.current = Date(timeIntervalSince1970: 181)
        motion.push(.stationaryOnly)
        try? await Task.sleep(for: .milliseconds(10))  // Wait for final event
        await XCTAssertEqualAsync(await emitted.count, 2)
    }
}
// Helper actor to collect events in a thread-safe way
actor EventCollector {
    private(set) var events: [ServiceEvent] = []
    
    var count: Int { events.count }
    
    func append(_ event: ServiceEvent) {
        events.append(event)
    }
}

// Helper function for async assertions
func XCTAssertEqualAsync<T: Equatable>(_ expression1: @autoclosure () async throws -> T, 
                                        _ expression2: @autoclosure () async throws -> T,
                                        file: StaticString = #filePath,
                                        line: UInt = #line) async {
    do {
        let value1 = try await expression1()
        let value2 = try await expression2()
        XCTAssertEqual(value1, value2, file: file, line: line)
    } catch {
        XCTFail("Threw error: \(error)", file: file, line: line)
    }
}

