// Root view that bootstraps all feature view models and wires them into the tab bar.
// Also manages the one-time Motion & Fitness permission prompt shown on first launch.

import SwiftUI
import GreenRouteDomain
import GreenRouteData
import GreenRouteService

/// The root SwiftUI view. Shows a loading state while dependencies are set up,
/// an error view if setup fails, or the main tab bar when ready
struct AppCompositionRoot: View {

    let service: any GreenRouteService

    @State private var greenBreakViewModel: GreenBreakViewModel?
    @State private var greenMeetingViewModel: GreenMeetingViewModel?
    @State private var settingsViewModel: SettingsViewModel?
    @State private var bootstrapError: String?
    /// Flag to ensure the motion permission prompt is shown once (usually on initial launch)
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

    /// Createes repositories, use cases, and view models.
    /// Runs once on launch. Sets bootstrapError on failure.
    @MainActor
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

/// One-time informational sheet explaining that GreenRoute uses Motion & Fitness data.
/// Does not request permission directly. Instructs the user to enable it in Settings.
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
