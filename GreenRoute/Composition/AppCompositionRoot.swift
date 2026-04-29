//
//  AppCompositionRoot.swift
//  GreenRoute
//
//  Created by Freja Egelund Grønnemose on 14/04/2026.
//
import SwiftUI
import GreenRouteDomain
import GreenRouteData
import GreenRouteService

struct AppCompositionRoot: View {

    let service: any GreenRouteService

    @State private var greenBreakViewModel: GreenBreakViewModel?
    @State private var greenMeetingViewModel: GreenMeetingViewModel?
    @State private var settingsViewModel: SettingsViewModel?
    @State private var bootstrapError: String?
    @AppStorage("motionSheetSeen") private var motionSheetSeen = false
    @State private var showMotionSheet = false

    var body: some View {
        Group {
            if let greenBreakViewModel, let greenMeetingViewModel, let settingsViewModel {
                TabView {
                    NavigationStack {
                        GreenBreakView(viewModel: greenBreakViewModel)
                    }
                    .tabItem { Label("Home", systemImage: "leaf.fill") }

                    NavigationStack {
                        GreenMeetingView(viewModel: greenMeetingViewModel)
                    }
                    .tabItem { Label("Green Meeting", systemImage: "figure.walk") }

                    NavigationStack {
                        SettingsView(viewModel: settingsViewModel)
                    }
                    .tabItem { Label("Settings", systemImage: "gearshape") }
                }
                .sheet(isPresented: $showMotionSheet) {
                    MotionPermissionPrompt(isPresented: $showMotionSheet)
                        .presentationDetents([.medium])
                }
                .task {
                    guard !motionSheetSeen else { return }
                    motionSheetSeen = true
                    try? await Task.sleep(for: .seconds(2))
                    showMotionSheet = true
                }
            } else if let error = bootstrapError {
                ContentUnavailableView(
                    "Could not start app",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                ProgressView("Setting up…")
                    .task { await bootstrap() }
            }
        }
    }

    private func bootstrap() async {
        do {

            let container = try ModelContainerFactory.makePersistentContainer()
            let recommendationRepository = SwiftDataRecommendationRepository(container: container)
            let inactivityRepository = SwiftDataInactivityEventRepository(container: container)
            let locationVisitRepository = SwiftDataLocationVisitRepository(container: container)

            let locationStore = LocationStore()

            let generateUseCase = GenerateGreenBreakUseCase(
                greenAreaProvider: service.greenAreaProvider,
                recommendationEngine: RecommendationEngine(),
                recommendationRepository: recommendationRepository,
                notificationPolicy: NotificationPolicy(maxPerDay: 2, minimumInterval: 4 * 60 * 60),
                notificationScheduler: service.notificationScheduler
            )

            let recordUseCase = RecordInactivityEventUseCase(repository: inactivityRepository)

            let settingsRepository = UserDefaultsSettingsRepository()

            greenBreakViewModel = GreenBreakViewModel(
                service: service,
                useCase: generateUseCase,
                recordUseCase: recordUseCase,
                locationVisitRepository: locationVisitRepository,
                locationStore: locationStore,
                settingsRepository: settingsRepository
            )

            greenMeetingViewModel = GreenMeetingViewModel(
                greenAreaProvider: service.greenAreaProvider,
                routeProvider: service.routeProvider,
                locationStore: locationStore
            )
            settingsViewModel = SettingsViewModel(repository: settingsRepository)
        } catch {
            bootstrapError = error.localizedDescription
        }
    }
}

private struct MotionPermissionPrompt: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.walk.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("Enable Motion & Fitness")
                    .font(.title2.bold())
                Text("GreenRoute uses motion data to detect when you've been sitting too long and nudge you to take a green break.\n\nHead to **Settings → Permissions** to enable it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Got It") {
                isPresented = false
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 4)
        }
        .padding(32)
    }
}
