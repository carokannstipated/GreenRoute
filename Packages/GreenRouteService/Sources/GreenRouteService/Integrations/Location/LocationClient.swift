//
//  LocationUpdate.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//


import Foundation

struct LocationUpdate: Sendable {
    let latitude: Double
    let longitude: Double
}

protocol LocationClient {
    func requestWhenInUsePermission()
    func startMonitoringSignificantLocationChanges(handler: @escaping @Sendable (LocationUpdate) -> Void)
    func stopMonitoringSignificantLocationChanges()
}