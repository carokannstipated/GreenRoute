//
//  GreenBreakView.swift
//  GreenRoute
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//


import SwiftUI
import GreenRouteDomain

struct GreenBreakView: View {

    @State private var viewModel: GreenBreakViewModel

    init(viewModel: GreenBreakViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            background
            VStack {
                Spacer()
                if let recommendation = viewModel.recommendation {
                    RecommendationCard(
                        recommendation: recommendation,
                        onAccept: { viewModel.acceptRecommendation() },
                        onDismiss: { viewModel.dismissRecommendation() }
                    )
                } else {
                    idleView
                    
                    Spacer().frame(maxHeight: 90)

                    Button {
                        /* Action 1 */
                    } label: {
                        Label("Generate Green Route", systemImage: "")
                            .frame(maxWidth: .infinity, maxHeight: 40)
                            .font(.title3.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    Spacer()
                }
              Spacer()
            }
            .padding()
        }
        .task {
            await viewModel.start()
            // Keep the task alive until cancelled (when view disappears)
            do {
                // Sleep for a very long time - will be cancelled when view disappears
                try await Task.sleep(for: .seconds(86400 * 365 * 100)) // 100 years
            } catch {
                // Task was cancelled
            }
            await viewModel.stop()
        }
        .sheet(isPresented: $viewModel.isShowingMap) {
            if let recommendation = viewModel.recommendation {
                RouteMapView(
                    recommendation: recommendation,
                    origin: viewModel.lastKnownCoordinate
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
                    Button {
                        Task { await viewModel.simulateInactivity() }
                    } label: {
                        Label("Simulate Inactivity", systemImage: "clock.badge.exclamationmark")
                    }
                    #endif
                    
                    // future settings items go here
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [Color.green.opacity(0.08), Color(.systemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

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

            /*
            #if DEBUG
            Button {
                Task { await viewModel.simulateInactivity() }
            } label: {
                Label("Simulate Inactivity", systemImage: "clock.badge.exclamationmark")
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
            #endif
             */
        }
    }
}

#Preview {
    AppCompositionRoot()
}
