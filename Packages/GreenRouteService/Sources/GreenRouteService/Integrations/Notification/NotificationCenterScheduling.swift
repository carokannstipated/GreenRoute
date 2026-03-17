//
//  NotificationCenterScheduling.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//

import UserNotifications

protocol NotificationCenterScheduling: Sendable {
    func add(_ request: UNNotificationRequest) async throws
}

// Wrapper around the singleton — keeps the protocol clean and avoids
// retroactive Sendable conformance on UNUserNotificationCenter.
final class LiveNotificationCenter: NotificationCenterScheduling {
    func add(_ request: UNNotificationRequest) async throws {
        try await UNUserNotificationCenter.current().add(request)
    }
}
