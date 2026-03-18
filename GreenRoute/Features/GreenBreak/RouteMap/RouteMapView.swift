//
//  RouteMapView.swift
//  GreenRoute
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//


import SwiftUI
import MapKit
import GreenRouteDomain

struct RouteMapView: View {

    @State private var viewModel: RouteMapViewModel
    @State private var position: MapCameraPosition
    @Environment(\.dismiss) private var dismiss

    init(recommendation: Recommendation, origin: Coordinate?) {
        let vm = RouteMapViewModel(recommendation: recommendation, origin: origin)
        _viewModel = State(initialValue: vm)
        _position = State(initialValue: .region(vm.initialRegion))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $position) {
                UserAnnotation()

                Marker(
                    viewModel.recommendation.target.name,
                    systemImage: "leaf.fill",
                    coordinate: viewModel.destinationCoordinate
                )
                .tint(.green)

                if let route = viewModel.route {
                    MapPolyline(route)
                        .stroke(.green, lineWidth: 5)
                }
            }
            .mapControls {
                MapCompass()
                MapUserLocationButton()
            }
            .ignoresSafeArea(edges: .top)
            .onChange(of: viewModel.route) { _, route in
                guard let route else { return }
                let rect = route.polyline.boundingMapRect
                let padded = rect.insetBy(
                    dx: -rect.size.width * 0.25,
                    dy: -rect.size.height * 0.25
                )
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
                    viewModel.openInMaps()
                } label: {
                    Label("Open in Maps", systemImage: "map")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
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
