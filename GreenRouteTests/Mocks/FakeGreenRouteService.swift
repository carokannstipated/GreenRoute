//
//  FakeGreenRouteService.swift
//  GreenRoute
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//


import Foundation
import GreenRouteDomain
@testable import GreenRouteService

final class FakeGreenRouteService: GreenRouteService, @unchecked Sendable {

    var greenAreaProvider: any GreenAreaProvider = FakeGreenAreaProvider()
    var notificationScheduler: any NotificationScheduler = FakeNotificationScheduler()
    var routeProvider: any RouteProvider = FakeRouteProvider()
    var inactivityChecker: any InactivityChecking = FakeInactivityChecker()

    private let continuation: AsyncStream<ServiceEvent>.Continuation
    let events: AsyncStream<ServiceEvent>

    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0

    init() {
        var localContinuation: AsyncStream<ServiceEvent>.Continuation!
        self.events = AsyncStream { localContinuation = $0 }
        self.continuation = localContinuation
    }

    func start() async { startCallCount += 1 }
    func stop() async { stopCallCount += 1 }

    func emit(_ event: ServiceEvent) {
        continuation.yield(event)
    }
}

final class FakeRouteProvider: RouteProvider, @unchecked Sendable {
    func calculateRoute(from: Coordinate, to: Coordinate) async throws -> RouteResult {
        RouteResult(coordinates: [], expectedTravelTimeSeconds: 0)
    }
}

actor FakeInactivityChecker: InactivityChecking {
    private(set) var checkCount = 0
    func checkInactivity() async { checkCount += 1 }
}

final class FakeGreenAreaProvider: GreenAreaProvider, @unchecked Sendable {
    var stubbedAreas: [GreenArea] = []
    func fetchGreenAreas(near coordinate: Coordinate, radius: DistanceMeters) async throws -> [GreenArea] {
        stubbedAreas
    }
}

final class FakeNotificationScheduler: NotificationScheduler, @unchecked Sendable {
    private(set) var scheduledRequests: [NotificationRequest] = []
    func schedule(_ request: NotificationRequest) async throws {
        scheduledRequests.append(request)
    }
}

final class FakeRecommendationRepository: RecommendationRepository, @unchecked Sendable {
    private(set) var saved: [Recommendation] = []
    func save(_ recommendation: Recommendation) async throws { saved.append(recommendation) }
    func fetch(from start: Date, to end: Date) async throws -> [Recommendation] { saved }
}
