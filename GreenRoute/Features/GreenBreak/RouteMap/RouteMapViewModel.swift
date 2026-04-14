//
//  RouteMapViewModel.swift
//  GreenRoute
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//

import Foundation
import GreenRouteDomain

@MainActor
@Observable
final class RouteMapViewModel {

    var outboundResult: RouteResult?
    var isLoadingRoute = false
    var routeError: String?

    let recommendation: Recommendation
    private let origin: Coordinate?
    private let routeProvider: any RouteProvider

    var destinationCoordinate: Coordinate {
        recommendation.target.coordinate
    }

    var initialRegion: (center: Coordinate, meters: Double) {
        (recommendation.target.coordinate, 1500)
    }

    init(recommendation: Recommendation, origin: Coordinate?, routeProvider: any RouteProvider) {
        self.recommendation = recommendation
        self.origin = origin
        self.routeProvider = routeProvider
    }

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

    func openInMaps() {
        // Passed to View which handles MapKit
    }
}
