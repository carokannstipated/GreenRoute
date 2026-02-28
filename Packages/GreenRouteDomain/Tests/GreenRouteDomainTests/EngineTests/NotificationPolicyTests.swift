//
//  NotificationPolicyTests.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import XCTest
@testable import GreenRouteDomain

final class NotificationPolicyTests: XCTestCase {

    func test_canSend_returnsFalse_whenMaxPerDayReached() {
        let policy = NotificationPolicy(maxPerDay: 2, minimumInterval: 0)
        let now = iso("2026-02-01T12:00:00Z")

        XCTAssertFalse(policy.canSend(sentCountToday: 2, lastSentAt: nil, now: now))
        XCTAssertFalse(policy.canSend(sentCountToday: 3, lastSentAt: nil, now: now))
    }

    func test_canSend_returnsFalse_whenWithinCooldown() {
        let policy = NotificationPolicy(maxPerDay: 2, minimumInterval: 4 * 60 * 60) // 4 hours
        let last = iso("2026-02-01T08:30:00Z")
        let now = iso("2026-02-01T12:00:00Z") // 3.5 hours later

        XCTAssertFalse(policy.canSend(sentCountToday: 0, lastSentAt: last, now: now))
    }

    func test_canSend_returnsTrue_whenUnderMaxAndCooldownPassed() {
        let policy = NotificationPolicy(maxPerDay: 2, minimumInterval: 4 * 60 * 60) // 4 hours
        let last = iso("2026-02-01T07:00:00Z")
        let now = iso("2026-02-01T12:00:00Z") // 5 hours later

        XCTAssertTrue(policy.canSend(sentCountToday: 1, lastSentAt: last, now: now))
    }

    func test_canSend_returnsTrue_whenNoPreviousNotificationAndUnderMax() {
        let policy = NotificationPolicy(maxPerDay: 2, minimumInterval: 4 * 60 * 60)
        let now = iso("2026-02-01T12:00:00Z")

        XCTAssertTrue(policy.canSend(sentCountToday: 0, lastSentAt: nil, now: now))
    }
}

// MARK: - Helpers

private func iso(_ value: String) -> Date {
    ISO8601DateFormatter().date(from: value)!
}
