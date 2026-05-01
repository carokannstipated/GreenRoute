// Production CLLocationManager adapter that bridges delegate callbacks into
// the closure-based LocationClient protocol.

import Foundation
import CoreLocation

/// `NSObject` subclass required to conform to `CLLocationManagerDelegate`.
/// Converts delegate calls into invocations of the stored `handler` closure.
final class CoreLocationClient: NSObject, LocationClient {

    private let manager = CLLocationManager()

    /// Stored closure invoked on each location update; retained here because
    /// `CLLocationManager` holds only a weak delegate reference.
    private var handler: (@Sendable (LocationUpdate) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestLocation() {
        manager.requestLocation()
    }

    func requestWhenInUsePermission() {
        manager.requestAlwaysAuthorization()
    }

    func startMonitoringSignificantLocationChanges(handler: @escaping @Sendable (LocationUpdate) -> Void) {
        self.handler = handler
        manager.startMonitoringSignificantLocationChanges()
    }

    func stopMonitoringSignificantLocationChanges() {
        manager.stopMonitoringSignificantLocationChanges()
        handler = nil
    }
}

extension CoreLocationClient: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        handler?(LocationUpdate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        ))
    }

    /// Significant-location-change failures are non-fatal in the current implementation.
    /// Errors are intentionally not surfaced; telemetry integration is deferred.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
}
