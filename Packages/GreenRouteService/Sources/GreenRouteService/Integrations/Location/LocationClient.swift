// Defines the LocationClient protocol and the LocationUpdate value type that
// decouple Core Location from the LocationMonitor actor.

import Foundation

/// A raw coordinate snapshot delivered by a `LocationClient` update.
struct LocationUpdate: Sendable {
    let latitude: Double
    let longitude: Double
}

/// Abstracts `CLLocationManager` to allow injection of test doubles into `LocationMonitor`.
protocol LocationClient {
    /// Requests always-on location authorisation from the user.
    func requestWhenInUsePermission()
    /// Requests a single one-shot location fix.
    func requestLocation()
    /// Begins continuous significant-change monitoring, invoking `handler` on each update.
    func startMonitoringSignificantLocationChanges(handler: @escaping @Sendable (LocationUpdate) -> Void)
    /// Stops significant-change monitoring and discards the stored handler.
    func stopMonitoringSignificantLocationChanges()
}
