// MapKit-backed RouteProvider that calculates pedestrian walking directions
// between two coordinates and converts the polyline into domain Coordinate values.

import Foundation
import MapKit
import GreenRouteDomain

/// `RouteProvider` implementation that uses `MKDirections` with `.walking` transport type.
final class MKRouteProvider: RouteProvider {

    /// Calculates a walking route from `from` to `to` using MapKit directions.
    /// - Returns: A `RouteResult` containing the polyline coordinates and expected travel time.
    /// - Throws: `RouteProviderError.noRouteFound` if MapKit returns no routes,
    ///   or any `MKError` propagated from the directions request.
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

        // Use the first (best) route returned by MapKit.
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

/// Errors that `MKRouteProvider` can throw in addition to underlying `MKError` values.
enum RouteProviderError: Error {
    /// MapKit returned a successful response but included no route alternatives.
    case noRouteFound
}

private extension MKPolyline {
    /// Extracts the underlying `CLLocationCoordinate2D` array from the polyline's C buffer.
    var coordinates: [CLLocationCoordinate2D] {
        var result = [CLLocationCoordinate2D](repeating: .init(), count: pointCount)
        getCoordinates(&result, range: NSRange(location: 0, length: pointCount))
        return result
    }
}
