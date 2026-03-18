//
//  LocationMonitor.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//

import Foundation
import GreenRouteDomain

actor LocationMonitor {

    struct Config: Sendable {
        // Reserved for dwell-time threshold when pattern detection is introduced.
    }

    private let location: LocationClient
    private let clock: Clock
    private let emit: @Sendable (ServiceEvent) -> Void

    init(
        location: LocationClient,
        clock: Clock,
        config: Config = Config(),
        emit: @escaping @Sendable (ServiceEvent) -> Void
    ) {
        self.location = location
        self.clock = clock
        self.emit = emit
    }

    func start() {
        location.requestWhenInUsePermission()

        location.startMonitoringSignificantLocationChanges { [weak self] update in
            guard let self else { return }
            Task {
                await self.handle(update)
            }
        }
        location.requestLocation()
        
    }

    func stop() {
        location.stopMonitoringSignificantLocationChanges()
    }

    private func handle(_ update: LocationUpdate) {
        let now = clock.now()
        let coordinate = Coordinate(latitude: update.latitude, longitude: update.longitude)

        emit(.significantLocationChange(latitude: update.latitude, longitude: update.longitude))

        let visit = LocationVisit(
            coordinate: coordinate,
            arrival: now,
            departure: nil,
            placeCategory: classifyCategory(at: now)
        )
        emit(.locationVisit(visit))
    }

    // Time-of-day heuristic — MVP placeholder.
    // Replace with learned patterns when PatternDetector is wired into the service layer.
    private func classifyCategory(at date: Date) -> PlaceCategory {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 7...9, 18...23: return .home
        case 9...18:         return .workOrStudy
        default:             return .other
        }
    }
}
