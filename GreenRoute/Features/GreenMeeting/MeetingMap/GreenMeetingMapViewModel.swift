//
//  GreenMeetingMapViewModel.swift
//  GreenRoute
//
//  Created by Freja Egelund Grønnemose on 14/04/2026.
//


import Foundation
import GreenRouteDomain

@MainActor
@Observable
final class GreenMeetingMapViewModel {

    var outboundResult: RouteResult?
    var returnResult: RouteResult?
    var isLoadingRoute = false
    var routeError: String?

    let greenArea: GreenArea
    let origin: Coordinate
    let totalDurationMinutes: Int

    private let routeProvider: any RouteProvider

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

    func loadRoutes() async {
        isLoadingRoute = true
        defer { isLoadingRoute = false }

        do {
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
