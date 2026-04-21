//
//  MKRouteProvider.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 14/04/2026.
//


import Foundation
import MapKit
import GreenRouteDomain

final class MKRouteProvider: RouteProvider {

    func calculateRoute(from: Coordinate, to: Coordinate) async throws -> RouteResult {
        let request = MKDirections.Request()
        request.transportType = .walking
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(
            latitude: from.latitude, longitude: from.longitude
        )))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(
            latitude: to.latitude, longitude: to.longitude
        )))

        let response = try await MKDirections(request: request).calculate()

        guard let route = response.routes.first else {
            throw RouteProviderError.noRouteFound
        }

        let coordinates = route.polyline.coordinates.map {
            Coordinate(latitude: $0.latitude, longitude: $0.longitude)
        }

        return RouteResult(
            coordinates: coordinates,
            expectedTravelTimeSeconds: route.expectedTravelTime
        )
    }
}

enum RouteProviderError: Error {
    case noRouteFound
}

// Convenience extension to extract coordinates from MKPolyline
private extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var result = [CLLocationCoordinate2D](repeating: .init(), count: pointCount)
        getCoordinates(&result, range: NSRange(location: 0, length: pointCount))
        return result
    }
}
