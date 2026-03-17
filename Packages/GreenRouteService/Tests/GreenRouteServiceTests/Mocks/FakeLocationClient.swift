//
//  FakeLocationClient.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//

@testable import GreenRouteService

final class FakeLocationClient: LocationClient, @unchecked Sendable {

    private(set) var permissionRequested = false
    private(set) var isMonitoring = false
    private var handler: (@Sendable (LocationUpdate) -> Void)?

    func requestWhenInUsePermission() {
        permissionRequested = true
    }

    func startMonitoringSignificantLocationChanges(handler: @escaping @Sendable (LocationUpdate) -> Void) {
        isMonitoring = true
        self.handler = handler
    }

    func stopMonitoringSignificantLocationChanges() {
        isMonitoring = false
        handler = nil
    }

    func push(_ update: LocationUpdate) {
        handler?(update)
    }
}
