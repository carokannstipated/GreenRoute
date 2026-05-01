// Async service contracts for external data sources and device infrastructure.

import Foundation

/// Supplies nearby green areas from an external source (e.g. a map API or a local cache).
public protocol GreenAreaProvider: Sendable {

    /// Fetches green areas whose centres lie within `radius` of `coordinate`.
    func fetchGreenAreas(
        near coordinate: Coordinate,
        radius: DistanceMeters
    ) async throws -> [GreenArea]
}

/// The outcome of a route calculation between two coordinates.
public struct RouteResult: Sendable, Equatable {

    /// Ordered sequence of coordinates forming the route polyline.
    public let coordinates: [Coordinate]

    /// Estimated travel time along this route in seconds.
    public let expectedTravelTimeSeconds: TimeInterval

    public init(coordinates: [Coordinate], expectedTravelTimeSeconds: TimeInterval) {
        self.coordinates = coordinates
        self.expectedTravelTimeSeconds = expectedTravelTimeSeconds
    }
}

/// Calculates a walking route between two geographic points.
public protocol RouteProvider: Sendable {

    func calculateRoute(from: Coordinate, to: Coordinate) async throws -> RouteResult
}

/// All data needed to deliver a single scheduled push notification.
public struct NotificationRequest: Equatable, Hashable, Sendable {

    /// Unique identifier used to cancel or replace this notification later.
    public let id: String

    /// Short headline displayed in the notification banner.
    public let title: String

    /// Secondary text with destination name and walk time estimate.
    public let body: String

    /// When the notification should be delivered. Must be in the future.
    public let fireAt: Date

    public init(id: String, title: String, body: String, fireAt: Date) {
        precondition(!id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "NotificationRequest id must not be empty")
        self.id = id
        self.title = title
        self.body = body
        self.fireAt = fireAt
    }
}

/// Platform-agnostic contract for scheduling a local push notification.
public protocol NotificationScheduler: Sendable {

    /// Submits the request to the underlying notification system.
    func schedule(_ request: NotificationRequest) async throws
}
