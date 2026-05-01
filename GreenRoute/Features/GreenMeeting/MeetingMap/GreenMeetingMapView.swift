// Map sheet for the Green Meeting feature. Shows a circular route (origin → green area → origin)
// with outbound and return legs drawn in distinct green shades.

import SwiftUI
import MapKit
import GreenRouteDomain

/// Displays both legs of a Green Meeting circular walk on a map.
/// The camera fits the combined polyline of both legs on load, then switches to
/// user-heading mode when navigation is started.
struct GreenMeetingMapView: View {

    @State private var viewModel: GreenMeetingMapViewModel
    /// Drives the MapKit camera programmatically.
    @State private var position: MapCameraPosition
    /// Bound to GreenMeetingViewModel.isWalking so the parent reflects navigation state.
    @Binding var isNavigating: Bool
    @Environment(\.dismiss) private var dismiss

    /// - Parameters:
    ///   - greenArea: The green area to route through.
    ///   - origin: The user's starting and ending point for the circular walk.
    ///   - totalDurationMinutes: The meeting duration chosen by the user, retained for display.
    ///   - routeProvider: Used to calculate both walking legs.
    ///   - isNavigating: Binding that the parent uses to track whether a walk is in progress.
    init(greenArea: GreenArea, origin: Coordinate, totalDurationMinutes: Int, routeProvider: any RouteProvider, isNavigating: Binding<Bool>) {
        let vm = GreenMeetingMapViewModel(
            greenArea: greenArea,
            origin: origin,
            totalDurationMinutes: totalDurationMinutes,
            routeProvider: routeProvider
        )
        _viewModel = State(initialValue: vm)
        _isNavigating = isNavigating
        // Start centred on the green area at a zoom level that shows the neighbourhood.
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: greenArea.coordinate.latitude,
                longitude: greenArea.coordinate.longitude
            ),
            latitudinalMeters: 2000,
            longitudinalMeters: 2000
        )))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                UserAnnotation()

                // Blue pin marks the start/end of the circular walk.
                Marker("Start / End", systemImage: "mappin.circle.fill",
                    coordinate: CLLocationCoordinate2D(
                        latitude: viewModel.origin.latitude,
                        longitude: viewModel.origin.longitude
                    )
                )
                .tint(.blue)

                // Green pin marks the green area meeting point.
                Marker(viewModel.greenArea.name, systemImage: "leaf.fill",
                    coordinate: CLLocationCoordinate2D(
                        latitude: viewModel.greenArea.coordinate.latitude,
                        longitude: viewModel.greenArea.coordinate.longitude
                    )
                )
                .tint(.green)

                // Outbound leg drawn in solid green.
                if let outbound = viewModel.outboundResult {
                    MapPolyline(coordinates: outbound.coordinates.map {
                        CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                    })
                    .stroke(.green, lineWidth: 5)
                }

                // Return leg drawn at half opacity to visually distinguish it from the outbound.
                if let returning = viewModel.returnResult {
                    MapPolyline(coordinates: returning.coordinates.map {
                        CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                    })
                    .stroke(.green.opacity(0.5), lineWidth: 5)
                }
            }
            .mapControls {
                MapCompass()
                MapUserLocationButton()
            }
            .ignoresSafeArea(edges: .top)
            .onChange(of: viewModel.returnResult) { _, _ in
                // Wait until the return leg is available so the camera can fit both legs together.
                guard !isNavigating else { return }
                guard let c1 = viewModel.outboundResult?.coordinates,
                      let c2 = viewModel.returnResult?.coordinates else { return }
                let all = (c1 + c2).map {
                    CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                }
                let polyline = MKPolyline(coordinates: all, count: all.count)
                let rect = polyline.boundingMapRect
                let padded = rect.insetBy(dx: -rect.size.width * 0.25, dy: -rect.size.height * 0.25)
                withAnimation { position = .rect(padded) }
            }

            bottomCard
        }
        .task { await viewModel.loadRoutes() }
        .overlay(alignment: .center) {
            if viewModel.isLoadingRoute {
                ProgressView()
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    /// Bottom card showing the green area name, combined travel time, and the start/stop button.
    private var bottomCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Via \(viewModel.greenArea.name)")
                        .font(.headline)
                    if viewModel.outboundResult != nil {
                        Text("~\(viewModel.combinedTravelTimeMinutes) min · circular walk")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Calculating route...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button {
                    isNavigating.toggle()
                    withAnimation {
                        if isNavigating {
                            // Switch to heading-tracking mode for navigation.
                            position = .userLocation(followsHeading: true, fallback: .automatic)
                        } else {
                            // Return to the full route overview when navigation stops.
                            guard let c1 = viewModel.outboundResult?.coordinates,
                                  let c2 = viewModel.returnResult?.coordinates else { return }
                            let all = (c1 + c2).map {
                                CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                            }
                            let polyline = MKPolyline(coordinates: all, count: all.count)
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
                .disabled(viewModel.outboundResult == nil) // Disabled until at least the outbound leg is ready.
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
