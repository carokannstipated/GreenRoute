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
    
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            AppCompositionRoot()
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Show notifications even when app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
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

            let recordUseCase = RecordInactivityEventUseCase(repository: inactivityRepository)

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

            viewModel = GreenBreakViewModel(service: service, useCase: useCase, recordUseCase: recordUseCase)
        } catch {
            bootstrapError = error.localizedDescription
        }
    }
}
