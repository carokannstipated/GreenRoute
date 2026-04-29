//  FakeNotificationCenter.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//

@preconcurrency import UserNotifications
@testable import GreenRouteService

// Sendable snapshot of notification request for testing
struct NotificationRequestSnapshot: Sendable {
    let identifier: String
    let title: String
    let body: String
    let sound: UNNotificationSound?
    let trigger: TriggerSnapshot?
    
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

actor FakeNotificationCenter: NotificationCenterScheduling {

    private var scheduledRequests: [UNNotificationRequest] = []
    private(set) var stubbedError: Error?
    
    func setStubbedError(_ error: Error?) {
        stubbedError = error
    }
    
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
