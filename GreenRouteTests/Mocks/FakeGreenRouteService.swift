//
//  FakeGreenRouteService.swift
//  GreenRoute
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//
// Test doubles for the GreenRouteService protocol and its collaborator protocols.
// Each fake is minimal: it records calls, exposes stubs, and avoids real networking or I/O.

import Foundation
import GreenRouteDomain
@testable import GreenRouteService

/// In-memory GreenRouteService that exposes an event stream controllable from tests.
/// Tracks start/stop call counts so tests can assert on service lifecycle.
final class FakeGreenRouteService: GreenRouteService, @unchecked Sendable {

    var greenAreaProvider: any GreenAreaProvider = FakeGreenAreaProvider()
    var notificationScheduler: any NotificationScheduler = FakeNotificationScheduler()
    var routeProvider: any RouteProvider = FakeRouteProvider()
    var inactivityChecker: any InactivityChecking = FakeInactivityChecker()

    /// Continuation used by emit(_:) to push events into the async stream consumed by the view model.
    private let continuation: AsyncStream<ServiceEvent>.Continuation
    let events: AsyncStream<ServiceEvent>

    /// Number of times start() has been called. Used to assert the service is started exactly once.
    private(set) var startCallCount = 0
    /// Number of times stop() has been called. Used to assert the service is stopped on teardown.
    private(set) var stopCallCount = 0

    init() {
        var localContinuation: AsyncStream<ServiceEvent>.Continuation!
        self.events = AsyncStream { localContinuation = $0 }
        self.continuation = localContinuation
    }

    func start() async { startCallCount += 1 }
    func stop() async { stopCallCount += 1 }

    /// Injects a ServiceEvent into the stream, simulating a real event from the service layer.
    func emit(_ event: ServiceEvent) {
        continuation.yield(event)
    }
}

/// Always returns an empty route with zero travel time. Sufficient for tests that don't assert on routing.
final class FakeRouteProvider: RouteProvider, @unchecked Sendable {
    func calculateRoute(from: Coordinate, to: Coordinate) async throws -> RouteResult {
        RouteResult(coordinates: [], expectedTravelTimeSeconds: 0)
    }
}

/// Records how many times checkInactivity() is called and returns a configurable stubbed event.
actor FakeInactivityChecker: InactivityChecking {
    private(set) var checkCount = 0
    /// Set to a non-nil value to simulate an inactivity detection.
    var stubbedEvent: InactivityEvent?

    func checkInactivity() async -> InactivityEvent? {
        checkCount += 1
        return stubbedEvent
    }
}

/// Returns a configurable list of green areas. Shared between the service fake and the use case under test.
final class FakeGreenAreaProvider: GreenAreaProvider, @unchecked Sendable {
    /// Set before each test scenario to control which areas are returned by fetchGreenAreas.
    var stubbedAreas: [GreenArea] = []
    func fetchGreenAreas(near coordinate: Coordinate, radius: DistanceMeters) async throws -> [GreenArea] {
        stubbedAreas
    }
}

/// Accumulates all scheduled notification requests so tests can assert on notification delivery.
final class FakeNotificationScheduler: NotificationScheduler, @unchecked Sendable {
    private(set) var scheduledRequests: [NotificationRequest] = []
    func schedule(_ request: NotificationRequest) async throws {
        scheduledRequests.append(request)
    }
}

/// In-memory recommendation repository. Stores saves in an array and returns them on fetch.
final class FakeRecommendationRepository: RecommendationRepository, @unchecked Sendable {
    private(set) var saved: [Recommendation] = []
    func save(_ recommendation: Recommendation) async throws { saved.append(recommendation) }
    func fetch(from start: Date, to end: Date) async throws -> [Recommendation] { saved }
}
