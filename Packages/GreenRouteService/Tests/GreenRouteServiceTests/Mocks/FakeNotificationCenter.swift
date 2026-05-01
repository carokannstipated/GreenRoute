// Test double for NotificationCenterScheduling that captures scheduled requests
// as Sendable snapshots so tests can inspect their content without involving the
// real UNUserNotificationCenter.

@preconcurrency import UserNotifications
@testable import GreenRouteService

/// A `Sendable` snapshot of a `UNNotificationRequest` for safe cross-actor inspection in tests.
/// Captures the identifier, content, and trigger details at scheduling time.
struct NotificationRequestSnapshot: Sendable {
    let identifier: String
    let title: String
    let body: String
    let sound: UNNotificationSound?
    let trigger: TriggerSnapshot?

    /// Sendable snapshot of calendar-trigger attributes.
    struct TriggerSnapshot: Sendable {
        let isCalendar: Bool
        let repeats: Bool
        let hour: Int?
        let minute: Int?
        let second: Int?
    }

    init(from request: UNNotificationRequest) {
        self.identifier = request.identifier
        self.title = request.content.title
        self.body = request.content.body
        self.sound = request.content.sound

        if let calendarTrigger = request.trigger as? UNCalendarNotificationTrigger {
            self.trigger = TriggerSnapshot(
                isCalendar: true,
                repeats: calendarTrigger.repeats,
                hour: calendarTrigger.dateComponents.hour,
                minute: calendarTrigger.dateComponents.minute,
                second: calendarTrigger.dateComponents.second
            )
        } else {
            self.trigger = nil
        }
    }
}

/// Records scheduled `UNNotificationRequest` objects and optionally throws a configurable error,
/// allowing tests to verify scheduling behaviour without interacting with the system.
actor FakeNotificationCenter: NotificationCenterScheduling {

    private var scheduledRequests: [UNNotificationRequest] = []

    /// When non-nil, `add(_:)` throws this error instead of recording the request.
    private(set) var stubbedError: Error?

    func setStubbedError(_ error: Error?) {
        stubbedError = error
    }

    /// Returns snapshots of all requests that have been successfully scheduled.
    func getScheduledRequests() -> [NotificationRequestSnapshot] {
        scheduledRequests.map { NotificationRequestSnapshot(from: $0) }
    }

    func getScheduledRequestCount() -> Int {
        scheduledRequests.count
    }

    nonisolated func add(_ request: UNNotificationRequest) async throws {
        try await _add(request)
    }

    private func _add(_ request: UNNotificationRequest) async throws {
        if let error = stubbedError { throw error }
        scheduledRequests.append(request)
    }
}
