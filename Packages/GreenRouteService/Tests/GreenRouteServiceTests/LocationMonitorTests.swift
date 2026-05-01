// Unit tests for LocationMonitor covering event emission correctness,
// PlaceCategory time-of-day classification, and monitor lifecycle (start/stop).

import XCTest
import GreenRouteDomain
@testable import GreenRouteService

final class LocationMonitorTests: XCTestCase {

    // MARK: - Event emission

    /// Verifies that a single location update causes exactly two events to be emitted:
    /// one `significantLocationChange` and one `locationVisit`.
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

    /// Verifies that the raw latitude and longitude values are forwarded without modification
    /// in the `significantLocationChange` event.
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

    /// Verifies that the `locationVisit` coordinate matches the raw update values.
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

    /// Verifies that a freshly created visit has no departure time, indicating the user
    /// is still present at the location when the visit is first recorded.
    func test_locationVisitIsOngoingAtCreation() async {
        let (monitor, location, _, emitted) = makeSUT()

        await monitor.start()
        location.push(LocationUpdate(latitude: 55.676, longitude: 12.568))
        try? await Task.sleep(for: .milliseconds(10))

        let events = await emitted.events
        let visit = locationVisit(from: events)
        XCTAssertTrue(visit?.isOngoing ?? false, "Visit should have no departure at creation")
    }

    // MARK: - PlaceCategory classification

    /// Verifies that an update arriving at 10:00 is classified as `.workOrStudy`
    /// by the time-of-day heuristic (9–18 range).
    func test_classifiesWorkHoursAsWorkOrStudy() async {
        let (monitor, location, _, emitted) = makeSUT(hour: 10)

        await monitor.start()
        location.push(LocationUpdate(latitude: 55.676, longitude: 12.568))
        try? await Task.sleep(for: .milliseconds(10))

        let events = await emitted.events
        XCTAssertEqual(locationVisit(from: events)?.placeCategory, .workOrStudy)
    }

    /// Verifies that 08:00 falls in the morning home window (7–9) and is classified as `.home`.
    func test_classifiesMorningCommutAsHome() async {
        let (monitor, location, _, emitted) = makeSUT(hour: 8)

        await monitor.start()
        location.push(LocationUpdate(latitude: 55.676, longitude: 12.568))
        try? await Task.sleep(for: .milliseconds(10))

        let events = await emitted.events
        XCTAssertEqual(locationVisit(from: events)?.placeCategory, .home)
    }

    /// Verifies that 20:00 falls in the evening home window (18–23) and is classified as `.home`.
    func test_classifiesEveningAsHome() async {
        let (monitor, location, _, emitted) = makeSUT(hour: 20)

        await monitor.start()
        location.push(LocationUpdate(latitude: 55.676, longitude: 12.568))
        try? await Task.sleep(for: .milliseconds(10))

        let events = await emitted.events
        XCTAssertEqual(locationVisit(from: events)?.placeCategory, .home)
    }

    /// Verifies that 03:00 (outside all named windows) is classified as `.other`.
    func test_classifiesLateNightAsOther() async {
        let (monitor, location, _, emitted) = makeSUT(hour: 3)

        await monitor.start()
        location.push(LocationUpdate(latitude: 55.676, longitude: 12.568))
        try? await Task.sleep(for: .milliseconds(10))

        let events = await emitted.events
        XCTAssertEqual(locationVisit(from: events)?.placeCategory, .other)
    }

    // MARK: - Lifecycle

    /// Verifies that `start()` triggers an authorisation request before monitoring begins.
    func test_requestsPermissionOnStart() async {
        let (monitor, location, _, _) = makeSUT()

        XCTAssertFalse(location.permissionRequested)
        await monitor.start()
        XCTAssertTrue(location.permissionRequested)
    }

    /// Verifies that significant-change monitoring is active after `start()`.
    func test_startsMonitoringOnStart() async {
        let (monitor, location, _, _) = makeSUT()

        await monitor.start()
        XCTAssertTrue(location.isMonitoring)
    }

    /// Verifies that significant-change monitoring is inactive after `stop()`.
    func test_stopsMonitoringOnStop() async {
        let (monitor, location, _, _) = makeSUT()

        await monitor.start()
        await monitor.stop()
        XCTAssertFalse(location.isMonitoring)
    }

    /// Verifies that updates delivered after `stop()` do not produce any emitted events,
    /// confirming the handler is nil'd out when monitoring ends.
    func test_noEventsAfterStop() async {
        let (monitor, location, _, emitted) = makeSUT()

        await monitor.start()
        await monitor.stop()
        location.push(LocationUpdate(latitude: 55.676, longitude: 12.568))
        try? await Task.sleep(for: .milliseconds(10))

        let events = await emitted.events
        XCTAssertTrue(events.isEmpty, "No events should be emitted after stop()")
    }

    /// Verifies that each location update independently emits two events, so two updates
    /// produce four events in total with no deduplication or merging.
    func test_multipleUpdatesEachEmitTwoEvents() async {
        let (monitor, location, _, emitted) = makeSUT()

        await monitor.start()
        location.push(LocationUpdate(latitude: 55.676, longitude: 12.568))
        location.push(LocationUpdate(latitude: 55.680, longitude: 12.570))
        try? await Task.sleep(for: .milliseconds(10))

        let events = await emitted.events
        XCTAssertEqual(events.count, 4)
    }

    // MARK: - Helpers

    private typealias SUT = (
        monitor: LocationMonitor,
        location: FakeLocationClient,
        clock: FakeClock,
        emitted: EventCollector
    )

    /// Builds a `LocationMonitor` with fakes and a fixed clock set to `hour` on 2026-03-17.
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

    /// Extracts the first `locationVisit` payload from a mixed event array.
    private func locationVisit(from events: [ServiceEvent]) -> LocationVisit? {
        events.compactMap {
            if case .locationVisit(let v) = $0 { return v }
            return nil
        }.first
    }

    /// Builds a `Date` for a specific hour on a fixed calendar day used throughout these tests.
    private func date(hour: Int) -> Date {
        var c = DateComponents()
        c.year = 2026; c.month = 3; c.day = 17
        c.hour = hour; c.minute = 0; c.second = 0
        return Calendar.current.date(from: c)!
    }
}
