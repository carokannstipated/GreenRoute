//
//  UserNotificationScheduler.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//


import Foundation
import UserNotifications
import GreenRouteDomain

final class UserNotificationScheduler: NotificationScheduler, Sendable {

    private let center: NotificationCenterScheduling

    init(center: NotificationCenterScheduling = LiveNotificationCenter()) {
        self.center = center
    }

    func schedule(_ request: NotificationRequest) async throws {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: request.fireAt
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let unRequest = UNNotificationRequest(
            identifier: request.id,
            content: content,
            trigger: trigger
        )

        try await center.add(unRequest)
    }
}
