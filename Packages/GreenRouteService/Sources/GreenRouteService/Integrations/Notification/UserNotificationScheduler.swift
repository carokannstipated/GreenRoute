// Converts domain NotificationRequest values into UNNotificationRequest objects
// and schedules them through a NotificationCenterScheduling implementation.

import Foundation
import UserNotifications
import GreenRouteDomain

/// `NotificationScheduler` implementation that maps `NotificationRequest` domain values
/// to `UNNotificationRequest` objects and hands them to the notification center.
final class UserNotificationScheduler: NotificationScheduler, Sendable {

    /// The notification center used to submit requests; injectable for testing.
    private let center: NotificationCenterScheduling

    init(center: NotificationCenterScheduling = LiveNotificationCenter()) {
        self.center = center
    }

    /// Builds a `UNNotificationRequest` from the domain request and schedules it.
    /// Uses a calendar trigger so the notification fires at the wall-clock time specified
    /// by `request.fireAt`, without repeating.
    func schedule(_ request: NotificationRequest) async throws {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = .default

        // Extract only hour/minute/second; the notification fires on the next matching time.
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: request.fireAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let unRequest = UNNotificationRequest(
            identifier: request.id,
            content: content,
            trigger: trigger
        )

        try await center.add(unRequest)
    }
}
