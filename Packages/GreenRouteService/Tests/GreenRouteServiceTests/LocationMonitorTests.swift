//
//  LocationMonitorTests.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//

import XCTest
import GreenRouteDomain
@testable import GreenRouteService

final class LocationMonitorTests: XCTestCase {

    // MARK: - Event emission

    func test_emitsBothEventsOnLocationUpdate() async {
        let (monitor, location, _, emitted) = makeSUT()

        await monitor.start()
        location.push(LocationUpdate(latitude: 55.676, longitude: 12.568))
        try? await Task.sleep(for: .milliseconds(10))

        let events = await emitted.events
        XCTAssertEqual(events.count, 2)
        XCTAssertTrue(events.contains { if case .significantLocationChange = $0 { return true }; return false })
        XCTAssertTrue(events.contains { if case .locationVisit = $0 { return true }; return false })
    }

    func test_significantLocationChangeCarriesCorrectCoordinates() async {
        let (monitor, location, _, emitted) = makeSUT()

        await monitor.start()
        location.push(LocationUpdate(latitude: 55.6761, longitude: 12.5683))
        try? await Task.sleep(for: .milliseconds(10))

        let events = await emitted.events
        let event = events.first {
            if case .significantLocationChange = $0 { return true }
            return false
        }

        guard case .significantLocationChange(let lat, let lon) = event else {
            return XCTFail("Expected significantLocationChange")
        }

        XCTAssertEqual(lat, 55.6761)
        XCTAssertEqual(lon, 12.5683)
    }

    func test_locationVisitCoordinateMatchesUpdate() async {
        let (monitor, location, _, emitted) = makeSUT()

        await monitor.start()
        location.push(LocationUpdate(latitude: 55.6761, longitude: 12.5683))
        try? await Task.sleep(for: .milliseconds(10))

        let events = await emitted.events
        let visit = locationVisit(from: events)
        XCTAssertEqual(visit?.coordinate.latitude, 55.6761)
        XCTAssertEqual(visit?.coordinate.longitude, 12.5683)
    }

    func test_locationVisitIsOngoingAtCreation() async {
        // Significant location change gives us an arrival with no departure yet.
        let (monitor, location, _, emitted) = makeSUT()

        await monitor.start()
        location.push(LocationUpdate(latitude: 55.676, longitude: 12.568))
        try? await Task.sleep(for: .milliseconds(10))

        let events = await emitted.events
        let visit = locationVisit(from: events)
        XCTAssertTrue(visit?.isOngoing ?? false, "Visit should have no departure at creation")
    }

    // MARK: - PlaceCategory classification

    func test_classifiesWorkHoursAsWorkOrStudy() async {
        let (monitor, location, _, emitted) = makeSUT(hour: 10)

        await monitor.start()
        location.push(LocationUpdate(latitude: 55.676, longitude: 12.568))
        try? await Task.sleep(for: .milliseconds(10))

        let events = await emitted.events
        XCTAssertEqual(locationVisit(from: events)?.placeCategory, .workOrStudy)
    }

    func test_classifiesMorningCommutAsHome() async {
        let (monitor, location, _, emitted) = makeSUT(hour: 8)

        await monitor.start()
        location.push(LocationUpdate(latitude: 55.676, longitude: 12.568))
        try? await Task.sleep(for: .milliseconds(10))

        let events = await emitted.events
        XCTAssertEqual(locationVisit(from: events)?.placeCategory, .home)
    }

    func test_classifiesEveningAsHome() async {
        let (monitor, location, _, emitted) = makeSUT(hour: 20)

        await monitor.start()
        location.push(LocationUpdate(latitude: 55.676, longitude: 12.568))
        try? await Task.sleep(for: .milliseconds(10))

        let events = await emitted.events
        XCTAssertEqual(locationVisit(from: events)?.placeCategory, .home)
    }

    func test_classifiesLateNightAsOther() async {
        let (monitor, location, _, emitted) = makeSUT(hour: 3)

        await monitor.start()
        location.push(LocationUpdate(latitude: 55.676, longitude: 12.568))
        try? await Task.sleep(for: .milliseconds(10))

        let events = await emitted.events
        XCTAssertEqual(locationVisit(from: events)?.placeCategory, .other)
    }

    // MARK: - Lifecycle

    func test_requestsPermissionOnStart() async {
        let (monitor, location, _, _) = makeSUT()

        XCTAssertFalse(location.permissionRequested)
        await monitor.start()
        XCTAssertTrue(location.permissionRequested)
    }

    func test_startsMonitoringOnStart() async {
        let (monitor, location, _, _) = makeSUT()

        await monitor.start()
        XCTAssertTrue(location.isMonitoring)
    }

    func test_stopsMonitoringOnStop() async {
        let (monitor, location, _, _) = makeSUT()

        await monitor.start()
        await monitor.stop()
        XCTAssertFalse(location.isMonitoring)
    }

    func test_noEventsAfterStop() async {
        let (monitor, location, _, emitted) = makeSUT()

        await monitor.start()
        await monitor.stop()
        location.push(LocationUpdate(latitude: 55.676, longitude: 12.568))
        try? await Task.sleep(for: .milliseconds(10))

        let events = await emitted.events
        XCTAssertTrue(events.isEmpty, "No events should be emitted after stop()")
    }

    func test_multipleUpdatesEachEmitTwoEvents() async {
        let (monitor, location, _, emitted) = makeSUT()

        await monitor.start()
        location.push(LocationUpdate(latitude: 55.676, longitude: 12.568))
        location.push(LocationUpdate(latitude: 55.680, longitude: 12.570))
        try? await Task.sleep(for: .milliseconds(10))

        let events = await emitted.events
        XCTAssertEqual(events.count, 4)
    }

    private typealias SUT = (
        monitor: LocationMonitor,
        location: FakeLocationClient,
        clock: FakeClock,
        emitted: EventCollector
    )

    private func makeSUT(hour: Int = 10) -> SUT {
        let location = FakeLocationClient()
        let clock = FakeClock(current: date(hour: hour))
        let emitted = EventCollector()

        let monitor = LocationMonitor(
            location: location,
            clock: clock,
            emit: { event in
                Task { await emitted.append(event) }
            }
        )
        return (monitor, location, clock, emitted)
    }

    private func locationVisit(from events: [ServiceEvent]) -> LocationVisit? {
        events.compactMap {
            if case .locationVisit(let v) = $0 { return v }
            return nil
        }.first
    }

    private func date(hour: Int) -> Date {
        var c = DateComponents()
        c.year = 2026; c.month = 3; c.day = 17
        c.hour = hour; c.minute = 0; c.second = 0
        return Calendar.current.date(from: c)!
    }
}
