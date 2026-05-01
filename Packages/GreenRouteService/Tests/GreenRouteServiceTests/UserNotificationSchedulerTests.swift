// Unit tests for UserNotificationScheduler covering content mapping,
// trigger configuration, error propagation, and call-count correctness.

import XCTest
import UserNotifications
import GreenRouteDomain
@testable import GreenRouteService

final class UserNotificationSchedulerTests: XCTestCase {

    // MARK: - Content mapping

    /// Verifies that the title from the domain request is forwarded into the
    /// scheduled notification's content without modification.
    func test_mapsTitleFromRequest() async throws {
        let (scheduler, center) = makeSUT()
        try await scheduler.schedule(makeRequest(title: "Green break?"))

        let requests = await center.getScheduledRequests()
        XCTAssertEqual(requests.first?.title, "Green break?")
    }

    /// Verifies that the body from the domain request is forwarded into the
    /// scheduled notification's content without modification.
    func test_mapsBodyFromRequest() async throws {
        let (scheduler, center) = makeSUT()
        try await scheduler.schedule(makeRequest(body: "Fælledparken is 200m away (~3 min walk)."))

        let requests = await center.getScheduledRequests()
        XCTAssertEqual(requests.first?.body, "Fælledparken is 200m away (~3 min walk).")
    }

    /// Verifies that the domain request's `id` becomes the `UNNotificationRequest` identifier,
    /// which is used by the system to deduplicate and cancel notifications.
    func test_mapsIdentifierFromRequest() async throws {
        let (scheduler, center) = makeSUT()
        try await scheduler.schedule(makeRequest(id: "greenroute.reco.abc123"))

        let requests = await center.getScheduledRequests()
        XCTAssertEqual(requests.first?.identifier, "greenroute.reco.abc123")
    }

    /// Verifies that a default sound is included so the notification attracts attention.
    func test_hasSoundEnabled() async throws {
        let (scheduler, center) = makeSUT()
        try await scheduler.schedule(makeRequest())

        let requests = await center.getScheduledRequests()
        XCTAssertNotNil(requests.first?.sound)
    }

    // MARK: - Trigger mapping

    /// Verifies that the scheduler uses a `UNCalendarNotificationTrigger` (time-based)
    /// rather than a location or interval trigger.
    func test_usesCalendarTrigger() async throws {
        let (scheduler, center) = makeSUT()
        try await scheduler.schedule(makeRequest())

        let requests = await center.getScheduledRequests()
        XCTAssertTrue(requests.first?.trigger?.isCalendar ?? false, "Expected calendar trigger")
    }

    /// Verifies that the trigger is set to fire once and not repeat, since
    /// recommendations are one-shot notifications.
    func test_triggerDoesNotRepeat() async throws {
        let (scheduler, center) = makeSUT()
        try await scheduler.schedule(makeRequest())

        let requests = await center.getScheduledRequests()
        XCTAssertEqual(requests.first?.trigger?.repeats, false)
    }

    /// Verifies that the hour, minute, and second components from `fireAt` are correctly
    /// extracted and stored in the calendar trigger's `dateComponents`.
    func test_triggerFiresAtSpecifiedHourAndMinute() async throws {
        let (scheduler, center) = makeSUT()
        let fireDate = date(hour: 14, minute: 30, second: 45)
        try await scheduler.schedule(makeRequest(fireAt: fireDate))

        let requests = await center.getScheduledRequests()
        let trigger = requests.first?.trigger
        XCTAssertEqual(trigger?.hour, 14)
        XCTAssertEqual(trigger?.minute, 30)
        XCTAssertEqual(trigger?.second, 45)
    }

    // MARK: - Error propagation

    /// Verifies that an error thrown by the notification center is propagated to the caller
    /// without being silently dropped.
    func test_propagatesCenterError() async throws {
        let (scheduler, center) = makeSUT()
        await center.setStubbedError(URLError(.unknown))

        do {
            try await scheduler.schedule(makeRequest())
            XCTFail("Expected error to be thrown")
        } catch {
        }
    }

    // MARK: - Call count

    /// Verifies that a single `schedule` call results in exactly one notification
    /// being handed to the center, with no implicit batching or splitting.
    func test_schedulesExactlyOneNotificationPerCall() async throws {
        let (scheduler, center) = makeSUT()
        try await scheduler.schedule(makeRequest())

        let count = await center.getScheduledRequestCount()
        XCTAssertEqual(count, 1)
    }

    /// Verifies that multiple independent `schedule` calls each add a separate request
    /// to the center, confirming there is no deduplication by identifier on the scheduler side.
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

    /// Builds a `Date` on a fixed calendar day to ensure trigger component assertions are stable.
    private func date(hour: Int, minute: Int, second: Int = 0) -> Date {
        var c = DateComponents()
        c.year = 2026; c.month = 3; c.day = 17
        c.hour = hour; c.minute = minute; c.second = second
        return Calendar.current.date(from: c)!
    }
}
