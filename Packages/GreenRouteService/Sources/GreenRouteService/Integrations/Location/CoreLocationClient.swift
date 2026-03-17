//
//  CoreLocationClient.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//

import Foundation
import CoreLocation

final class CoreLocationClient: NSObject, LocationClient {

    private let manager = CLLocationManager()
    private var handler: (@Sendable (LocationUpdate) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestWhenInUsePermission() {
        manager.requestWhenInUseAuthorization()
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

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Surface to logging/telemetry in a future iteration.
        // Silently ignored in MVP — significant location change failures are non-fatal.
    }
}
