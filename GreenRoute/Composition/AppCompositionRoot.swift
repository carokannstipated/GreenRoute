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

    @State private var greenBreakViewModel: GreenBreakViewModel?
    @State private var greenMeetingViewModel: GreenMeetingViewModel?
    @State private var settingsViewModel: SettingsViewModel?
    @State private var bootstrapError: String?

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
            // Data
            let container = try ModelContainerFactory.makePersistentContainer()
            let recommendationRepository = SwiftDataRecommendationRepository(container: container)
            let inactivityRepository = SwiftDataInactivityEventRepository(container: container)

            // Shared location state
            let locationStore = LocationStore()

            // Service
            let service = GreenRouteServiceFactory.make()

            // Use cases
            let generateUseCase = GenerateGreenBreakUseCase(
                greenAreaProvider: service.greenAreaProvider,
                recommendationEngine: RecommendationEngine(),
                recommendationRepository: recommendationRepository,
                notificationPolicy: NotificationPolicy(maxPerDay: 2, minimumInterval: 4 * 60 * 60),
                notificationScheduler: service.notificationScheduler
            )

            let recordUseCase = RecordInactivityEventUseCase(repository: inactivityRepository)

            // Shared settings
            let settingsRepository = UserDefaultsSettingsRepository()

            // ViewModels
            greenBreakViewModel = GreenBreakViewModel(
                service: service,
                useCase: generateUseCase,
                recordUseCase: recordUseCase,
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
