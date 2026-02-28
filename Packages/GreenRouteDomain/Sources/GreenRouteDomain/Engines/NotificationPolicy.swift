//
//  NotificationPolicy.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import Foundation

public struct NotificationPolicy: Sendable {

    public let maxPerDay: Int
    public let minimumInterval: TimeInterval

    // - Parameters:
    //   - maxPerDay: Maximum notifications per calendar day (e.g. 2).
    //   - minimumInterval: Cooldown between notifications in seconds (e.g. 4 hours).
    public init(maxPerDay: Int = 2, minimumInterval: TimeInterval = 4 * 60 * 60) {
        precondition(maxPerDay >= 0, "maxPerDay cannot be negative")
        precondition(minimumInterval >= 0, "minimumInterval cannot be negative")

        self.maxPerDay = maxPerDay
        self.minimumInterval = minimumInterval
    }

    // Returns true if we're allowed to send a notification right now.
    //
    // - Parameters:
    //   - sentCountToday: How many notifications have already been sent today.
    //   - lastSentAt: Timestamp of last sent notification (if any).
    //   - now: Current time (inject for deterministic testing).
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
