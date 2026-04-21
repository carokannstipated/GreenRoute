//
//  GreenMeetingMapView.swift
//  GreenRoute
//
//  Created by Freja Egelund Grønnemose on 14/04/2026.
//


import SwiftUI
import MapKit
import GreenRouteDomain

struct GreenMeetingMapView: View {

    @State private var viewModel: GreenMeetingMapViewModel
    @State private var position: MapCameraPosition
    @State private var isNavigating = false
    @Environment(\.dismiss) private var dismiss

    init(greenArea: GreenArea, origin: Coordinate, totalDurationMinutes: Int, routeProvider: any RouteProvider) {
        let vm = GreenMeetingMapViewModel(
            greenArea: greenArea,
            origin: origin,
            totalDurationMinutes: totalDurationMinutes,
            routeProvider: routeProvider
        )
        _viewModel = State(initialValue: vm)
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

                Marker("Start / End", systemImage: "mappin.circle.fill",
                    coordinate: CLLocationCoordinate2D(
                        latitude: viewModel.origin.latitude,
                        longitude: viewModel.origin.longitude
                    )
                )
                .tint(.blue)

                Marker(viewModel.greenArea.name, systemImage: "leaf.fill",
                    coordinate: CLLocationCoordinate2D(
                        latitude: viewModel.greenArea.coordinate.latitude,
                        longitude: viewModel.greenArea.coordinate.longitude
                    )
                )
                .tint(.green)

                if let outbound = viewModel.outboundResult {
                    MapPolyline(coordinates: outbound.coordinates.map {
                        CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                    })
                    .stroke(.green, lineWidth: 5)
                }

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
                            position = .userLocation(followsHeading: true, fallback: .automatic)
                        } else {
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
