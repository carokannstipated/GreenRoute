//
//  RouteMapViewModel.swift
//  GreenRoute
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//

import Foundation
import MapKit
import GreenRouteDomain

@MainActor
@Observable
final class RouteMapViewModel {

    var route: MKRoute?
    var isLoadingRoute = false
    var routeError: String?

    let recommendation: Recommendation
    private let origin: Coordinate?

    var destinationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: recommendation.target.coordinate.latitude,
            longitude: recommendation.target.coordinate.longitude
        )
    }

    var initialRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: destinationCoordinate,
            latitudinalMeters: 1500,
            longitudinalMeters: 1500
        )
    }

    init(recommendation: Recommendation, origin: Coordinate?) {
        self.recommendation = recommendation
        self.origin = origin
    }

    func loadRoute() async {
        isLoadingRoute = true
        defer { isLoadingRoute = false }

        let request = MKDirections.Request()
        request.transportType = .walking

        if let origin {
            let originLocation = CLLocation(
                latitude: origin.latitude,
                longitude: origin.longitude
            )
            request.source = MKMapItem(location: originLocation, address: nil)
        } else {
            request.source = .forCurrentLocation()
        }

        let destinationLocation = CLLocation(
            latitude: destinationCoordinate.latitude,
            longitude: destinationCoordinate.longitude
        )
        request.destination = MKMapItem(location: destinationLocation, address: nil)

        do {
            let response = try await MKDirections(request: request).calculate()
            route = response.routes.first
        } catch {
            routeError = "Could not calculate route."
        }
    }

    func openInMaps() {
        let location = CLLocation(
            latitude: destinationCoordinate.latitude,
            longitude: destinationCoordinate.longitude
        )
        let item = MKMapItem(location: location, address: nil)
        item.name = recommendation.target.name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
}
