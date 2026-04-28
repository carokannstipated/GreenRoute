//
//  GreenRouteApp.swift
//  GreenRoute
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//

import SwiftUI
import BackgroundTasks
import GreenRouteDomain
import GreenRouteData
import GreenRouteService

@main
struct GreenRouteApp: App {

    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            AppCompositionRoot(service: appDelegate.service)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    nonisolated(unsafe) let service: any GreenRouteService = GreenRouteServiceFactory.make()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        registerBackgroundTask()
        scheduleBackgroundFetch()
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    private func registerBackgroundTask() {
        let checker = service.inactivityChecker
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.greenroute.inactivity",
            using: nil
        ) { task in
            Task { @MainActor [checker] in
                let work = Task.detached { await BackgroundFetchHandler.run(checker: checker) }
                task.expirationHandler = { work.cancel() }
                _ = await work.result
                task.setTaskCompleted(success: !work.isCancelled)
            }
        }
    }

    private func scheduleBackgroundFetch() {
        let request = BGAppRefreshTaskRequest(identifier: "com.greenroute.inactivity")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
}

private enum BackgroundFetchHandler {
    static func run(checker: any InactivityChecking) async {
        await checker.checkInactivity()

        do {
            let modelContainer = try ModelContainerFactory.makePersistentContainer()
            let inactivityRepo = SwiftDataInactivityEventRepository(container: modelContainer)
            let patternRepo = SwiftDataRecurringPatternRepository(container: modelContainer)
            let useCase = DetectRecurringPatternUseCase(
                inactivityRepository: inactivityRepo,
                patternRepository: patternRepo
            )
            _ = try await useCase.execute(now: Date(), calendar: Calendar.current)
        } catch {}

        let request = BGAppRefreshTaskRequest(identifier: "com.greenroute.inactivity")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
}
