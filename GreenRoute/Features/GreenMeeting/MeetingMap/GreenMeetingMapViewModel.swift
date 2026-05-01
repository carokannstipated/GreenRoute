//
//  GreenMeetingMapViewModel.swift
//  GreenRoute
//
//  Created by Freja Egelund Grønnemose on 14/04/2026.
//
// View model for the Green Meeting map sheet. Calculates both legs of a circular
// walk (origin → green area, green area → origin) and aggregates their travel times.

import Foundation
import GreenRouteDomain

/// Manages route calculation for the circular Green Meeting walk.
/// Both legs are fetched concurrently and exposed separately so the map can
/// draw outbound and return polylines with distinct styling.
@MainActor
@Observable
final class GreenMeetingMapViewModel {

    /// Walking route from the user's origin to the green area. Nil until the route loads.
    var outboundResult: RouteResult?
    /// Walking route from the green area back to the user's origin. Nil until the route loads.
    var returnResult: RouteResult?
    /// True while both route legs are being fetched, used to show a loading indicator.
    var isLoadingRoute = false
    /// Non-nil when route calculation fails; displayed in the bottom card.
    var routeError: String?

    /// The green area the meeting is centred on.
    let greenArea: GreenArea
    /// The user's starting and ending point for the circular walk.
    let origin: Coordinate
    /// The total meeting duration in minutes as specified by the user, retained for display purposes.
    let totalDurationMinutes: Int

    private let routeProvider: any RouteProvider

    /// Combined travel time for both legs rounded to the nearest minute.
    /// Returns 0 until at least one leg has loaded.
    var combinedTravelTimeMinutes: Int {
        let seconds = (outboundResult?.expectedTravelTimeSeconds ?? 0) +
                      (returnResult?.expectedTravelTimeSeconds ?? 0)
        return Int((seconds / 60).rounded())
    }

    init(greenArea: GreenArea, origin: Coordinate, totalDurationMinutes: Int, routeProvider: any RouteProvider) {
        self.greenArea = greenArea
        self.origin = origin
        self.totalDurationMinutes = totalDurationMinutes
        self.routeProvider = routeProvider
    }

    /// Fetches both route legs concurrently. On failure, sets routeError and leaves results nil.
    func loadRoutes() async {
        isLoadingRoute = true
        defer { isLoadingRoute = false }

        do {
            // Request both legs in parallel — neither depends on the other's result.
            async let leg1 = routeProvider.calculateRoute(from: origin, to: greenArea.coordinate)
            async let leg2 = routeProvider.calculateRoute(from: greenArea.coordinate, to: origin)
            let (outbound, returning) = try await (leg1, leg2)
            outboundResult = outbound
            returnResult = returning
        } catch {
            routeError = "Could not calculate walking route."
        }
    }
}
