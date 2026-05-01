// Observes significant location changes and emits both a raw coordinate event and
// a LocationVisit domain object for each update received.

import Foundation
import GreenRouteDomain

/// Wraps a `LocationClient` and converts each location update into two service events:
/// a `significantLocationChange` (raw coordinates) and a `locationVisit` (domain object).
actor LocationMonitor {

    /// Placeholder for future dwell-time and visit-detection tuning parameters.
    struct Config: Sendable {
    }

    private let location: LocationClient
    private let clock: Clock
    /// Closure used to forward domain events to the `DependencyContainer`.
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

    /// Requests location permission, starts significant-change monitoring, and requests
    /// an immediate one-shot fix so the first event is delivered without waiting for movement.
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

    /// Stops significant-change monitoring and discards the update handler.
    func stop() {
        location.stopMonitoringSignificantLocationChanges()
    }

    /// Converts a raw `LocationUpdate` into two emitted events.
    /// The `LocationVisit` is created with a nil departure because the user has just arrived.
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

    /// Time-of-day heuristic for MVP place classification.
    /// Morning (7–9) and evening (18–23) are treated as home; mid-day as work/study;
    /// late night and early morning as other. Replace with learned patterns once
    /// pattern detection is wired into the service layer.
    private func classifyCategory(at date: Date) -> PlaceCategory {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 7...9, 18...23: return .home
        case 9...18:         return .workOrStudy
        default:             return .other
        }
    }
}
