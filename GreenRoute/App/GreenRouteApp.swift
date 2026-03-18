//
//  GreenRouteApp.swift
//  GreenRoute
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//


import SwiftUI
import GreenRouteDomain
import GreenRouteData
import GreenRouteService

@main
struct GreenRouteApp: App {
    var body: some Scene {
        WindowGroup {
            AppCompositionRoot()
        }
    }
}

struct AppCompositionRoot: View {

    @State private var viewModel: GreenBreakViewModel?
    @State private var bootstrapError: String?

    var body: some View {
        Group {
            if let viewModel {
                NavigationStack {
                    GreenBreakView(viewModel: viewModel)
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

            // Service
            let service = GreenRouteServiceFactory.make()

            // Use case — wires service platform implementations into domain logic
            let useCase = GenerateGreenBreakUseCase(
                greenAreaProvider: service.greenAreaProvider,
                recommendationEngine: RecommendationEngine(),
                recommendationRepository: recommendationRepository,
                notificationPolicy: NotificationPolicy(maxPerDay: 2, minimumInterval: 4 * 60 * 60),
                notificationScheduler: service.notificationScheduler
            )

            viewModel = GreenBreakViewModel(service: service, useCase: useCase)
        } catch {
            bootstrapError = error.localizedDescription
        }
    }
}
