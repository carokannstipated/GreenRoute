//
//  GreenRouteServiceFacade.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 03/03/2026.
//

import Foundation
import GreenRouteDomain

public protocol GreenRouteService: Sendable {
    var events: AsyncStream<ServiceEvent> { get }
    var greenAreaProvider: any GreenAreaProvider { get }
    var notificationScheduler: any NotificationScheduler { get }
    var routeProvider: any RouteProvider { get }
    var inactivityChecker: any InactivityChecking { get }
    func start() async
    func stop() async
}


public final class GreenRouteServiceFacade: GreenRouteService, @unchecked Sendable {

    private let container: DependencyContainer

    public let notificationScheduler: any NotificationScheduler
    public let greenAreaProvider: any GreenAreaProvider
    public let routeProvider: any RouteProvider
    public let inactivityChecker: any InactivityChecking

    private let stream: AsyncStream<ServiceEvent>
    private let continuation: AsyncStream<ServiceEvent>.Continuation

    public var events: AsyncStream<ServiceEvent> { stream }

    init(
        container: DependencyContainer,
        notificationScheduler: any NotificationScheduler,
        greenAreaProvider: any GreenAreaProvider,
        routeProvider: any RouteProvider,
        inactivityChecker: any InactivityChecking
    ) {
        self.container = container
        self.notificationScheduler = notificationScheduler
        self.greenAreaProvider = greenAreaProvider
        self.routeProvider = routeProvider
        self.inactivityChecker = inactivityChecker

        var localContinuation: AsyncStream<ServiceEvent>.Continuation!
        self.stream = AsyncStream { continuation in
            localContinuation = continuation
        }
        self.continuation = localContinuation

        let continuation = self.continuation
        Task {
            await container.bindEventSink { event in
                continuation.yield(event)
            }
        }
    }

    public func start() async {
        await container.start()
    }

    public func stop() async {
        continuation.finish()
        await container.stop()
    }
}
