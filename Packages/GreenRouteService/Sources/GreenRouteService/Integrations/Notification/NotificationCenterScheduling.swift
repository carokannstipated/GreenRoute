// Defines the NotificationCenterScheduling protocol and its live adapter,
// isolating UNUserNotificationCenter from the scheduler logic for testability.

import UserNotifications

/// Abstracts the `UNUserNotificationCenter.add(_:)` call so `UserNotificationScheduler`
/// can be tested without scheduling real system notifications.
protocol NotificationCenterScheduling: Sendable {
    /// Schedules a notification request with the system notification center.
    /// - Throws: Any error produced by `UNUserNotificationCenter`.
    func add(_ request: UNNotificationRequest) async throws
}

/// Production adapter that delegates directly to the `UNUserNotificationCenter` singleton.
/// Wrapping the singleton avoids the need for a retroactive `Sendable` conformance on
/// `UNUserNotificationCenter` itself.
final class LiveNotificationCenter: NotificationCenterScheduling {
    func add(_ request: UNNotificationRequest) async throws {
        try await UNUserNotificationCenter.current().add(request)
    }
}
