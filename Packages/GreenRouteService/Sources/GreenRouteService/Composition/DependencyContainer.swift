import Foundation
import GreenRouteDomain

actor DependencyContainer {
    typealias EventSink = @Sendable (ServiceEvent) -> Void

    private var eventSink: EventSink?
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

    struct Providers: Sendable {
        let notificationScheduler: NotificationScheduler
        let greenAreaProvider: GreenAreaProvider
        let routeProvider: RouteProvider
        let inactivityChecker: any InactivityChecking
    }

    static func production() -> (container: DependencyContainer, providers: Providers) {
        let motion = CoreMotionMotionClient()
        let location = CoreLocationClient()
        let clock = SystemClock()

        let notificationScheduler = UserNotificationScheduler()
        let greenAreaProvider = MapKitGreenAreaProvider()
        let routeProvider = MKRouteProvider()

        final class Box: @unchecked Sendable { var container: DependencyContainer? }
        let box = Box()

        let inactivityMonitor = InactivityMonitor(
            motion: motion,
            clock: clock,
            config: .init(inactivityThreshold: 20 * 60),
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
        box.container = container

        let providers = Providers(
            notificationScheduler: notificationScheduler,
            greenAreaProvider: greenAreaProvider,
            routeProvider: routeProvider,
            inactivityChecker: inactivityMonitor
        )

        return (container, providers)
    }

    func bindEventSink(_ sink: @escaping EventSink) {
        self.eventSink = sink
    }

    func emit(_ event: ServiceEvent) {
        self.eventSink?(event)
    }

    func start() async {
        guard !self.isRunning else { return }
        self.isRunning = true
        await self.inactivityMonitor.start()
        await self.locationMonitor.start()
    }

    func stop() async {
        guard self.isRunning else { return }
        self.isRunning = false
        await self.inactivityMonitor.stop()
        await self.locationMonitor.stop()
    }
}
