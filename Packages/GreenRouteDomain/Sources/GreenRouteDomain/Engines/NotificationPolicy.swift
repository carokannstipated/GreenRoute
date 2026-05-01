// Enforces per-day cap and minimum cooldown between outgoing green-break notifications.

import Foundation

/// An immutable rule set that determines whether a notification may be sent right now.
///
/// All inputs are passed explicitly so the policy remains pure and testable without
/// mocking any global state. Callers are responsible for tracking `sentCountToday`
/// and `lastSentAt` across the app's lifetime.
public struct NotificationPolicy: Sendable {

    /// Maximum number of notifications that may be sent within a single calendar day.
    /// Defaults to 2.
    public let maxPerDay: Int

    /// Minimum number of seconds that must have elapsed since the last notification
    /// before another one is allowed. Defaults to 4 hours.
    public let minimumInterval: TimeInterval

    public init(maxPerDay: Int = 2, minimumInterval: TimeInterval = 4 * 60 * 60) {
        precondition(maxPerDay >= 0, "maxPerDay cannot be negative")
        precondition(minimumInterval >= 0, "minimumInterval cannot be negative")

        self.maxPerDay = maxPerDay
        self.minimumInterval = minimumInterval
    }

    /// Returns `true` when both the daily cap and the cooldown constraint are satisfied.
    ///
    /// - Parameters:
    ///   - sentCountToday: How many notifications have already been sent today.
    ///   - lastSentAt: When the most recent notification was delivered, or `nil` if none.
    ///   - now: The current time, used to calculate the elapsed interval since `lastSentAt`.
    public func canSend(
        sentCountToday: Int,
        lastSentAt: Date?,
        now: Date
    ) -> Bool {
        precondition(sentCountToday >= 0, "sentCountToday cannot be negative")

        guard sentCountToday < maxPerDay else { return false }

        if let lastSentAt {
            let sinceLast = now.timeIntervalSince(lastSentAt)
            guard sinceLast >= minimumInterval else { return false }
        }

        return true
    }
}
