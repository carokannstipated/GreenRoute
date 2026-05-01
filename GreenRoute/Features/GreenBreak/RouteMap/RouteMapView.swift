// Map sheet for a single green break recommendation. Shows the walking route
// as a polyline, centres the camera on the full route, and lets the user
// toggle turn-by-turn navigation mode.

import SwiftUI
import MapKit
import GreenRouteDomain

/// Fullscreen map sheet displayed when the user accepts a green break recommendation.
struct RouteMapView: View {

    @State private var viewModel: RouteMapViewModel
    /// Drives the MapKit camera. Updated programmatically to fit the polyline or follow the user.
    @State private var position: MapCameraPosition
    /// Bound to GreenBreakViewModel.isWalking so the parent reflects navigation state.
    @Binding var isNavigating: Bool
    @Environment(\.dismiss) private var dismiss

    /// - Parameters:
    ///   - recommendation: The green area recommendation to route to.
    ///   - origin: The user's location at the time the sheet opened. Nil falls back to the destination.
    ///   - routeProvider: Used by the view model to calculate the walking route.
    ///   - isNavigating: Binding that the parent uses to track whether a walk is in progress.
    init(recommendation: Recommendation, origin: Coordinate?, routeProvider: any RouteProvider, isNavigating: Binding<Bool>) {
        let vm = RouteMapViewModel(recommendation: recommendation, origin: origin, routeProvider: routeProvider)
        _viewModel = State(initialValue: vm)
        _isNavigating = isNavigating
        // Start centred on the destination at a comfortable zoom level before the route loads.
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: recommendation.target.coordinate.latitude,
                longitude: recommendation.target.coordinate.longitude
            ),
            latitudinalMeters: 1500,
            longitudinalMeters: 1500
        )))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                UserAnnotation()

                Marker(
                    viewModel.recommendation.target.name,
                    systemImage: "leaf.fill",
                    coordinate: CLLocationCoordinate2D(
                        latitude: viewModel.destinationCoordinate.latitude,
                        longitude: viewModel.destinationCoordinate.longitude
                    )
                )
                .tint(.green)

                if let result = viewModel.outboundResult {
                    MapPolyline(coordinates: result.coordinates.map {
                        CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                    })
                    .stroke(.green, lineWidth: 5)
                }
            }
            .mapControls { MapCompass(); MapUserLocationButton() }
            .ignoresSafeArea(edges: .top)
            .onChange(of: viewModel.outboundResult) { _, result in
                // Once the route loads, zoom to show the full polyline
                // Skip this if the user is already navigating and has switched to heading mode.
                guard !isNavigating else { return }
                guard let coords = result?.coordinates, !coords.isEmpty else { return }
                let clCoords = coords.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                let polyline = MKPolyline(coordinates: clCoords, count: clCoords.count)
                let rect = polyline.boundingMapRect
                let padded = rect.insetBy(dx: -rect.size.width * 0.25, dy: -rect.size.height * 0.25)
                withAnimation { position = .rect(padded) }
            }

            bottomCard
        }
        .task { await viewModel.loadRoute() }
        .overlay(alignment: .center) {
            if viewModel.isLoadingRoute {
                ProgressView()
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    /// Bottom card showing destination info and the start/stop navigation button.
    private var bottomCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.recommendation.target.name)
                        .font(.headline)
                    Text("\(Int(viewModel.recommendation.distance.value))m · ~\(viewModel.recommendation.estimatedWalkMinutes) min walk")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    isNavigating.toggle()
                    withAnimation {
                        if isNavigating {
                            // Switch to user-tracking heading mode for turn-by-turn navigation.
                            position = .userLocation(followsHeading: true, fallback: .automatic)
                        } else {
                            // Return to route overview when navigation is stopped.
                            guard let coords = viewModel.outboundResult?.coordinates,
                                  !coords.isEmpty else { return }
                            let clCoords = coords.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                            let polyline = MKPolyline(coordinates: clCoords, count: clCoords.count)
                            let rect = polyline.boundingMapRect
                            let padded = rect.insetBy(dx: -rect.size.width * 0.25, dy: -rect.size.height * 0.25)
                            position = .rect(padded)
                        }
                    }
                } label: {
                    Label(
                        isNavigating ? "Stop" : "Start walk",
                        systemImage: isNavigating ? "stop.circle" : "figure.walk.circle.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(isNavigating ? .red : .green)
                .disabled(viewModel.outboundResult == nil) // Disabled until the route has loaded.
            }

            if let error = viewModel.routeError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding()
    }
}
