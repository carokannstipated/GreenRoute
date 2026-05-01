//
//  GreenMeetingView.swift
//  GreenRoute
//
// Entry screen for the Green Meeting feature. Lets the user pick a meeting duration
// with a wheel picker, then searches for a suitable green area and opens the map sheet.

import SwiftUI

/// Presents a duration picker and a "Start Green Meeting" button.
/// While a session is active, replaces the picker with a session pill at the top of the screen.
struct GreenMeetingView: View {

    @State private var viewModel: GreenMeetingViewModel
    /// Hours component of the user-selected duration.
    @State private var hours = 0
    /// Minutes component of the user-selected duration. Defaults to 30 minutes.
    @State private var minutes = 30

    init(viewModel: GreenMeetingViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack() {
            background

            if viewModel.isWalking && !viewModel.isShowingMap {
                // Active session with the map sheet closed — show the session pill.
                sessionPill
            } else {
                VStack(spacing: 24) {
                    Text("Meeting Duration")
                        .font(.largeTitle.bold())

                    picker

                    Spacer().frame(maxHeight: 5)

                    Button {
                        Task { await viewModel.startMeeting(hours: hours, minutes: minutes) }
                    } label: {
                        Group {
                            if viewModel.isSearching {
                                ProgressView()
                            } else {
                                Label("Start Green Meeting", systemImage: "figure.walk")
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: 40)
                        .font(.title3.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .padding(.horizontal)
                    // Disabled during search or when the user has left duration at zero.
                    .disabled(viewModel.isSearching || (hours == 0 && minutes == 0))
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingMap) {
            if let greenArea = viewModel.foundGreenArea {
                GreenMeetingMapView(
                    greenArea: greenArea,
                    origin: viewModel.currentCoordinate,
                    totalDurationMinutes: (hours * 60) + minutes,
                    routeProvider: viewModel.routeProvider,
                    isNavigating: $viewModel.isWalking
                )
                .presentationDragIndicator(.visible)
            }
        }
        .alert(
            "Could not find route",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    /// Side-by-side hour and minute wheel pickers with inline unit labels.
    private var picker: some View {
        HStack(spacing: 0) {
            Text("hrs")
                .font(.body.bold())
                .frame(width: 50, alignment: .trailing)

            Picker("Hours", selection: $hours) {
                ForEach(0..<24) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)

            Picker("Min", selection: $minutes) {
                ForEach(0..<60) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)

            Text("min")
                .font(.body.bold())
                .frame(width: 50, alignment: .leading)
        }
        .padding(.horizontal)
    }

    /// Floating pill shown when a meeting route is active but the map sheet is minimised.
    /// Tapping the left side reopens the sheet; the X button ends the session.
    private var sessionPill: some View {
        HStack(spacing: 12) {
            Button { viewModel.resumeSession() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .foregroundStyle(.green)
                    Text("Meeting route active")
                        .font(.subheadline.weight(.medium))
                }
            }
            Divider().frame(height: 16)
            Button { viewModel.endSession() } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect()
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    /// Subtle green-to-background gradient that fills the screen behind all content.
    private var background: some View {
        LinearGradient(
            colors: [Color.green.opacity(0.08), Color(.systemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
