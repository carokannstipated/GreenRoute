//
//  Providers.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import Foundation

// MARK: - Green areas (POI search abstraction)

public protocol GreenAreaProvider: Sendable {
    // Returns green areas near the given coordinate within a radius.
    func fetchGreenAreas(
        near coordinate: Coordinate,
        radius: DistanceMeters
    ) async throws -> [GreenArea]
}

// MARK: - Notifications (abstraction over UNUserNotificationCenter)

public struct NotificationRequest: Equatable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let body: String
    public let fireAt: Date

    public init(id: String, title: String, body: String, fireAt: Date) {
        precondition(!id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "NotificationRequest id must not be empty")
        self.id = id
        self.title = title
        self.body = body
        self.fireAt = fireAt
    }
}

public protocol NotificationScheduler: Sendable {
    func schedule(_ request: NotificationRequest) async throws
}
