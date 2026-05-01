//
//  RouteMapViewModel.swift
//  GreenRoute
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//
// View model for the Green Break route map sheet. Fetches the walking route
// from the user's current position to the recommended green area.

import Foundation
import GreenRouteDomain

/// Manages route loading for a single green break recommendation.
/// If the user's location is unavailable, falls back to the destination itself as the origin
/// so the map still renders something useful.
@MainActor
@Observable
final class RouteMapViewModel {

    /// The calculated walking route from origin to destination. Nil until the route loads.
    var outboundResult: RouteResult?
    /// True while the route request is in flight, used to show a loading indicator.
    var isLoadingRoute = false
    /// Non-nil when route calculation fails; displayed in the bottom card.
    var routeError: String?

    /// The recommendation driving this map session, retained for display (name, distance, walk time).
    let recommendation: Recommendation
    /// The user's location at the time the map was opened. Nil if location was unavailable.
    private let origin: Coordinate?
    private let routeProvider: any RouteProvider

    /// Convenience accessor for the green area's coordinate used by the map marker.
    var destinationCoordinate: Coordinate {
        recommendation.target.coordinate
    }

    /// Returns the destination coordinate and a default radius for the initial map region.
    var initialRegion: (center: Coordinate, meters: Double) {
        (recommendation.target.coordinate, 1500)
    }

    init(recommendation: Recommendation, origin: Coordinate?, routeProvider: any RouteProvider) {
        self.recommendation = recommendation
        self.origin = origin
        self.routeProvider = routeProvider
    }

    /// Fetches the walking route to the recommended destination.
    /// Falls back to using the destination as the origin if no user location is known,
    /// which results in a zero-length route but avoids a crash.
    func loadRoute() async {
        isLoadingRoute = true
        defer { isLoadingRoute = false }

        let from = origin ?? recommendation.target.coordinate
        do {
            outboundResult = try await routeProvider.calculateRoute(
                from: from,
                to: recommendation.target.coordinate
            )
        } catch {
            routeError = "Could not calculate route."
        }
    }

    /// Placeholder for a future "Open in Maps" deep-link action.
    func openInMaps() {

    }
}
