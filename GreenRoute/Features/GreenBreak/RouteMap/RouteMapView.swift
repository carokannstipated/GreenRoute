import SwiftUI
import MapKit
import GreenRouteDomain

struct RouteMapView: View {

    @State private var viewModel: RouteMapViewModel
    @State private var position: MapCameraPosition
    @Binding var isNavigating: Bool
    @Environment(\.dismiss) private var dismiss

    init(recommendation: Recommendation, origin: Coordinate?, routeProvider: any RouteProvider, isNavigating: Binding<Bool>) {
        let vm = RouteMapViewModel(recommendation: recommendation, origin: origin, routeProvider: routeProvider)
        _viewModel = State(initialValue: vm)
        _isNavigating = isNavigating
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
                            position = .userLocation(followsHeading: true, fallback: .automatic)
                        } else {
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
                .disabled(viewModel.outboundResult == nil)
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
