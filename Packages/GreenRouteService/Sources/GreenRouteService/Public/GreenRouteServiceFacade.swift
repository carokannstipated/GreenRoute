// Defines the GreenRouteService public protocol and its GreenRouteServiceFacade
// implementation, which bridges internal monitor events into an AsyncStream.

import Foundation
import GreenRouteDomain

/// The public interface to the service layer exposed to app targets.
/// Provides access to a live event stream and to the core system capabilities
/// (green area lookup, routing, notification scheduling, inactivity checking).
public protocol GreenRouteService: Sendable {
    /// Async stream of events emitted by the monitors; terminates when `stop()` is called.
    var events: AsyncStream<ServiceEvent> { get }
    var greenAreaProvider: any GreenAreaProvider { get }
    var notificationScheduler: any NotificationScheduler { get }
    var routeProvider: any RouteProvider { get }
    var inactivityChecker: any InactivityChecking { get }
    /// Starts location and inactivity monitoring.
    func start() async
    /// Finishes the event stream and stops all monitors.
    func stop() async
}

/// Concrete `GreenRouteService` that owns a `DependencyContainer` and bridges
/// its emitted events into an `AsyncStream<ServiceEvent>` via a stored continuation.
public final class GreenRouteServiceFacade: GreenRouteService, @unchecked Sendable {

    /// The internal dependency graph; manages monitor lifecycle.
    private let container: DependencyContainer

    public let notificationScheduler: any NotificationScheduler
    public let greenAreaProvider: any GreenAreaProvider
    public let routeProvider: any RouteProvider
    public let inactivityChecker: any InactivityChecking

    /// The backing storage for the public `events` stream.
    private let stream: AsyncStream<ServiceEvent>

    /// Held so `stop()` can terminate the stream when monitoring ends.
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

        // AsyncStream only exposes its continuation inside the initialiser closure,
        // so capture it into a local variable and assign it after the stream is created.
        var localContinuation: AsyncStream<ServiceEvent>.Continuation!
        self.stream = AsyncStream { continuation in
            localContinuation = continuation
        }
        self.continuation = localContinuation

        // Capture continuation by value so the Task closure doesn't retain self.
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

    /// Finishes the event stream before stopping the container so consumers
    /// see the stream end cleanly rather than simply receiving no more values.
    public func stop() async {
        continuation.finish()
        await container.stop()
    }
}
