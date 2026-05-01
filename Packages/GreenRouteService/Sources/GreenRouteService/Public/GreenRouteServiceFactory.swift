// Single entry point for app targets to create a fully configured production
// GreenRouteService without depending on internal implementation types.

import Foundation

/// Convenience factory that assembles the production service graph and returns it
/// as the opaque `GreenRouteService` protocol type, hiding all internal dependencies.
public enum GreenRouteServiceFactory {
    /// Creates and returns a ready-to-use production `GreenRouteService`.
    /// Call `start()` on the returned instance to begin monitoring.
    public static func make() -> any GreenRouteService {
        let (container, providers) = DependencyContainer.production()
        return GreenRouteServiceFacade(
            container: container,
            notificationScheduler: providers.notificationScheduler,
            greenAreaProvider: providers.greenAreaProvider,
            routeProvider: providers.routeProvider,
            inactivityChecker: providers.inactivityChecker
        )
    }
}
