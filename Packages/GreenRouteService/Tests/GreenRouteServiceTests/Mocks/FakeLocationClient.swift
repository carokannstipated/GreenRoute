// Test double for LocationClient that records permission/monitoring state and
// lets tests push synthetic LocationUpdate values into the monitor under test.

@testable import GreenRouteService

/// Simulates CLLocationManager behaviour without touching the real system framework.
/// Tests drive the monitor by calling `push(_:)` to inject location updates.
final class FakeLocationClient: LocationClient, @unchecked Sendable {

    /// Set to true when `requestWhenInUsePermission()` has been called.
    private(set) var permissionRequested = false

    /// True while `startMonitoringSignificantLocationChanges` is active.
    private(set) var isMonitoring = false

    /// The handler registered by `startMonitoringSignificantLocationChanges`; nil when not monitoring.
    private var handler: (@Sendable (LocationUpdate) -> Void)?

    func requestWhenInUsePermission() {
        permissionRequested = true
    }

    func requestLocation() {}

    func startMonitoringSignificantLocationChanges(handler: @escaping @Sendable (LocationUpdate) -> Void) {
        isMonitoring = true
        self.handler = handler
    }

    func stopMonitoringSignificantLocationChanges() {
        isMonitoring = false
        handler = nil
    }

    /// Delivers a synthetic location update to the registered handler.
    /// Call this from tests to simulate the device changing position.
    func push(_ update: LocationUpdate) {
        handler?(update)
    }
}
