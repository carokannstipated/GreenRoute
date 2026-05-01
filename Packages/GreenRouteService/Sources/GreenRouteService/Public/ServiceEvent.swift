// Defines the ServiceEvent enum — the currency type flowing from the service layer
// to the app layer via the GreenRouteService.events async stream.

import Foundation
import GreenRouteDomain

/// Events emitted by the service layer. The app layer consumes these to trigger
/// recommendation logic, persistence writes, and UI updates.
public enum ServiceEvent: Sendable {
    /// Fired by `InactivityMonitor` when the user has been continuously stationary
    /// for the configured threshold duration.
    case inactivityDetected(InactivityEvent)

    /// Fired by `LocationMonitor` on each significant location change, providing
    /// a `LocationVisit` domain object with arrival time and a heuristic place category.
    case locationVisit(LocationVisit)

    /// Fired by `LocationMonitor` alongside `locationVisit`, providing raw coordinates
    /// for callers that only need the position without the full visit object.
    case significantLocationChange(latitude: Double, longitude: Double)
}
