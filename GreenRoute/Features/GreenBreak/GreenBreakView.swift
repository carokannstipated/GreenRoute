//
//  GreenBreakView.swift
//  GreenRoute
//
// Main home screen for the Green Break feature. Shows idle state, an active recommendation
// card, or a "no results" state with controls to retry. Also hosts the route map sheet.

import SwiftUI
import GreenRouteDomain

/// The primary view for the Green Break tab.
/// Starts and stops the service through its view model via the .task lifecycle modifier.
struct GreenBreakView: View {

    @State private var viewModel: GreenBreakViewModel

    init(viewModel: GreenBreakViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .top) {
            background

            // Session pill appears at the top when the user is walking but has minimised the map sheet.
            if viewModel.isWalking && !viewModel.isShowingMap {
                sessionPill
            }

            VStack {
                Spacer()

                if let recommendation = viewModel.recommendation, !viewModel.isWalking {
                    // A recommendation is ready and the user hasn't started walking yet.
                    RecommendationCard(
                        recommendation: recommendation,
                        onAccept: { viewModel.acceptRecommendation() },
                        onDismiss: { viewModel.dismissRecommendation() }
                    )
                } else if viewModel.noResultsNearby {
                    // A manual search completed but found nothing — offer a duration adjustment and retry.
                    noResultsView
                    Spacer().frame(maxHeight: 24)
                    durationStepper
                    Spacer().frame(maxHeight: 24)
                    Button {
                        Task { await viewModel.generateOnDemand() }
                    } label: {
                        Label("Try again", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity, maxHeight: 40)
                            .font(.title3.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                } else if viewModel.recommendation == nil {
                    // Idle state — app is monitoring in the background, nothing to show yet.
                    idleView
                    Spacer().frame(maxHeight: 90)
                    Button {
                        Task { await viewModel.generateOnDemand() }
                    } label: {
                        Label("Generate Green Route", systemImage: "leaf.arrow.circlepath")
                            .frame(maxWidth: .infinity, maxHeight: 40)
                            .font(.title3.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }

                Spacer()
            }
            .padding()
        }
        .onAppear { viewModel.reloadSettings() }
        // The .task modifier ties the service lifecycle to the view's lifetime.
        // The sleep after start() keeps the task alive indefinitely so service events
        // keep flowing; it is cancelled when the view disappears, which calls stop().
        .task {
            await viewModel.start()
            do {
                try await Task.sleep(for: .seconds(86400 * 365 * 100))
            } catch {
            }
            await viewModel.stop()
        }
        .sheet(isPresented: $viewModel.isShowingMap) {
            if let recommendation = viewModel.recommendation {
                RouteMapView(
                    recommendation: recommendation,
                    origin: viewModel.lastKnownCoordinate,
                    routeProvider: viewModel.routeProvider,
                    isNavigating: $viewModel.isWalking
                )
                .presentationDragIndicator(.visible)
            }
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    #if DEBUG
                    // Debug shortcut to test the inactivity → recommendation flow without waiting.
                    Button {
                        Task { await viewModel.simulateInactivity() }
                    } label: {
                        Label("Simulate Inactivity", systemImage: "clock.badge.exclamationmark")
                    }
                    #endif
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
    }

    /// Floating pill shown at the top of the screen when a walk is active but the map sheet is closed.
    /// Tapping the left side re-opens the sheet; the X button ends the session.
    private var sessionPill: some View {
        HStack(spacing: 12) {
            Button { viewModel.resumeSession() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .foregroundStyle(.green)
                    Text("Green Break active")
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

    private var background: some View {
        LinearGradient(
            colors: [Color.green.opacity(0.08), Color(.systemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    /// Inline stepper that lets the user adjust the max route duration during the no-results state
    /// without navigating to Settings.
    private var durationStepper: some View {
        HStack {
            Text("Max duration")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Stepper(
                "\(viewModel.maxRouteDurationMinutes) min",
                value: Binding(
                    get: { viewModel.maxRouteDurationMinutes },
                    set: { viewModel.setMaxRouteDuration($0) }
                ),
                in: 5...60,
                step: 5
            )
            .fixedSize()
        }
        .padding(.horizontal, 4)
    }

    /// Displayed when a manual search found no green areas within the current range.
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green.opacity(0.4))

            Text("Nothing nearby")
                .font(.largeTitle.bold())

            Text("No green areas within your current range. Try expanding the search area.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    /// Displayed when the app is monitoring in the background and no recommendation is active.
    private var idleView: some View {
        VStack(spacing: 20) {
            Image(systemName: "leaf.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("GreenRoute")
                .font(.largeTitle.bold())

            Text("We'll let you know when it's a good time for a green break.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
