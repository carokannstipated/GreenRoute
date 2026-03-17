//
//  UserNotificationSchedulerTests.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//


import XCTest
import UserNotifications
import GreenRouteDomain
@testable import GreenRouteService

final class UserNotificationSchedulerTests: XCTestCase {

    // MARK: - Content mapping

    func test_mapsTitleFromRequest() async throws {
        let (scheduler, center) = makeSUT()
        try await scheduler.schedule(makeRequest(title: "Green break?"))

        let requests = await center.getScheduledRequests()
        XCTAssertEqual(requests.first?.title, "Green break?")
    }

    func test_mapsBodyFromRequest() async throws {
        let (scheduler, center) = makeSUT()
        try await scheduler.schedule(makeRequest(body: "Fælledparken is 200m away (~3 min walk)."))

        let requests = await center.getScheduledRequests()
        XCTAssertEqual(requests.first?.body, "Fælledparken is 200m away (~3 min walk).")
    }

    func test_mapsIdentifierFromRequest() async throws {
        let (scheduler, center) = makeSUT()
        try await scheduler.schedule(makeRequest(id: "greenroute.reco.abc123"))

        let requests = await center.getScheduledRequests()
        XCTAssertEqual(requests.first?.identifier, "greenroute.reco.abc123")
    }

    func test_hasSoundEnabled() async throws {
        let (scheduler, center) = makeSUT()
        try await scheduler.schedule(makeRequest())

        let requests = await center.getScheduledRequests()
        XCTAssertNotNil(requests.first?.sound)
    }

    // MARK: - Trigger mapping

    func test_usesCalendarTrigger() async throws {
        let (scheduler, center) = makeSUT()
        try await scheduler.schedule(makeRequest())

        let requests = await center.getScheduledRequests()
        XCTAssertTrue(requests.first?.trigger?.isCalendar ?? false, "Expected calendar trigger")
    }

    func test_triggerDoesNotRepeat() async throws {
        let (scheduler, center) = makeSUT()
        try await scheduler.schedule(makeRequest())

        let requests = await center.getScheduledRequests()
        XCTAssertEqual(requests.first?.trigger?.repeats, false)
    }

    func test_triggerFiresAtSpecifiedHourAndMinute() async throws {
        let (scheduler, center) = makeSUT()
        let fireDate = date(hour: 14, minute: 30)
        try await scheduler.schedule(makeRequest(fireAt: fireDate))

        let requests = await center.getScheduledRequests()
        let trigger = requests.first?.trigger
        XCTAssertEqual(trigger?.hour, 14)
        XCTAssertEqual(trigger?.minute, 30)
    }

    // MARK: - Error propagation

    func test_propagatesCenterError() async throws {
        let (scheduler, center) = makeSUT()
        await center.setStubbedError(URLError(.unknown))

        do {
            try await scheduler.schedule(makeRequest())
            XCTFail("Expected error to be thrown")
        } catch {
            // pass
        }
    }

    // MARK: - Call count

    func test_schedulesExactlyOneNotificationPerCall() async throws {
        let (scheduler, center) = makeSUT()
        try await scheduler.schedule(makeRequest())

        let count = await center.getScheduledRequestCount()
        XCTAssertEqual(count, 1)
    }

    func test_schedulesMultipleCallsIndependently() async throws {
        let (scheduler, center) = makeSUT()
        try await scheduler.schedule(makeRequest(id: "id-1"))
        try await scheduler.schedule(makeRequest(id: "id-2"))

        let count = await center.getScheduledRequestCount()
        XCTAssertEqual(count, 2)
    }

    // MARK: - Helpers

    private typealias SUT = (scheduler: UserNotificationScheduler, center: FakeNotificationCenter)

    private func makeSUT() -> SUT {
        let center = FakeNotificationCenter()
        return (UserNotificationScheduler(center: center), center)
    }

    private func makeRequest(
        id: String = "test-id",
        title: String = "Green break?",
        body: String = "A park is nearby.",
        fireAt: Date? = nil
    ) -> NotificationRequest {
        NotificationRequest(id: id, title: title, body: body, fireAt: fireAt ?? date(hour: 13, minute: 0))
    }

    private func date(hour: Int, minute: Int) -> Date {
        var c = DateComponents()
        c.year = 2026; c.month = 3; c.day = 17
        c.hour = hour; c.minute = minute; c.second = 0
        return Calendar.current.date(from: c)!
    }
}
