// Wires together all production dependencies and coordinates the lifecycle of the
// InactivityMonitor and LocationMonitor actors.

import Foundation
import GreenRouteDomain

/// Owns all internal service dependencies and routes events from monitors to the registered sink.
/// Constructed once via `production()` and handed to `GreenRouteServiceFacade`.
actor DependencyContainer {

    /// Callback type used to forward service events from the monitors to the facade's async stream.
    typealias EventSink = @Sendable (ServiceEvent) -> Void

    /// The registered event handler; nil until the facade calls `bindEventSink(_:)`.
    private var eventSink: EventSink?

    /// Prevents double-start and double-stop calls.
    private var isRunning = false

    private let inactivityMonitor: InactivityMonitor
    private let locationMonitor: LocationMonitor

    private init(
        inactivityMonitor: InactivityMonitor,
        locationMonitor: LocationMonitor
    ) {
        self.inactivityMonitor = inactivityMonitor
        self.locationMonitor = locationMonitor
    }

    /// Value bundle that carries the read-only provider dependencies surfaced to the facade.
    struct Providers: Sendable {
        let notificationScheduler: NotificationScheduler
        let greenAreaProvider: GreenAreaProvider
        let routeProvider: RouteProvider
        let inactivityChecker: any InactivityChecking
    }

    /// Assembles the complete production object graph using real system services.
    /// Returns both the container (which owns monitor lifecycle) and the provider bundle.
    static func production() -> (container: DependencyContainer, providers: Providers) {
        let motion = CoreMotionMotionClient()
        let location = CoreLocationClient()
        let clock = SystemClock()

        let notificationScheduler = UserNotificationScheduler()
        let greenAreaProvider = MapKitGreenAreaProvider()
        let routeProvider = MKRouteProvider()

        // Box breaks the initialization cycle: monitors need to call container.emit(_:),
        // but the container doesn't exist yet when the monitors are created.
        final class Box: @unchecked Sendable { var container: DependencyContainer? }
        let box = Box()

        let inactivityMonitor = InactivityMonitor(
            motion: motion,
            clock: clock,
            config: .init(inactivityThreshold: 2 * 60),
            emit: { @Sendable event in
                guard let container = box.container else { return }
                Task {
                    await container.emit(event)
                }
            }
        )

        let locationMonitor = LocationMonitor(
            location: location,
            clock: clock,
            emit: { @Sendable event in
                guard let container = box.container else { return }
                Task {
                    await container.emit(event)
                }
            }
        )

        let container = DependencyContainer(
            inactivityMonitor: inactivityMonitor,
            locationMonitor: locationMonitor
        )
        // Resolve the cycle now that the container exists.
        box.container = container

        let providers = Providers(
            notificationScheduler: notificationScheduler,
            greenAreaProvider: greenAreaProvider,
            routeProvider: routeProvider,
            inactivityChecker: inactivityMonitor
        )

        return (container, providers)
    }

    /// Registers the closure that receives all events emitted by the monitors.
    /// Called once by `GreenRouteServiceFacade` to bridge events into its async stream.
    func bindEventSink(_ sink: @escaping EventSink) {
        self.eventSink = sink
    }

    /// Delivers an event to the registered sink. No-op if no sink has been bound yet.
    func emit(_ event: ServiceEvent) {
        self.eventSink?(event)
    }

    /// Starts both monitors. Subsequent calls before `stop()` are ignored.
    func start() async {
        guard !self.isRunning else { return }
        self.isRunning = true
        await self.inactivityMonitor.start()
        await self.locationMonitor.start()
    }

    /// Stops both monitors and resets the running flag. Subsequent calls before `start()` are ignored.
    func stop() async {
        guard self.isRunning else { return }
        self.isRunning = false
        await self.inactivityMonitor.stop()
        await self.locationMonitor.stop()
    }
}
