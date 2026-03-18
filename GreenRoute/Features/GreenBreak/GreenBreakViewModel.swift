//
//  GreenBreakViewModel.swift
//  GreenRoute
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//


import Foundation
import UserNotifications
import GreenRouteDomain
import GreenRouteService

@MainActor
@Observable
final class GreenBreakViewModel {

    // MARK: - UI State

    var recommendation: Recommendation?
    var isShowingMap = false
    var errorMessage: String?

    // MARK: - Internal state

    private(set) var lastKnownCoordinate: Coordinate?
    private var sentCountToday = 0
    private var lastNotificationSentAt: Date?
    private var observationTask: Task<Void, Never>?

    // MARK: - Dependencies

    private let service: any GreenRouteService
    private let useCase: GenerateGreenBreakUseCase
    private let policy: NotificationPolicy

    // MARK: - Config

    private let inactivityThresholdMinutes = 20
    private let maxDistance = DistanceMeters(value: 500)
    private let searchRadius = DistanceMeters(value: 500)

    init(
        service: any GreenRouteService,
        useCase: GenerateGreenBreakUseCase,
        policy: NotificationPolicy = NotificationPolicy()
    ) {
        self.service = service
        self.useCase = useCase
        self.policy = policy
    }

    // MARK: - Lifecycle

    func start() async {
        do {
            try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            // Permission denied — notifications won't fire but the app continues
        }

        await service.start()

        observationTask = Task { [weak self] in
            guard let self else { return }
            for await event in service.events {
                await self.handle(event)
            }
        }
    }

    func stop() async {
        observationTask?.cancel()
        observationTask = nil
        await service.stop()
    }

    // MARK: - User actions

    func acceptRecommendation() {
        isShowingMap = true
    }

    func dismissRecommendation() {
        recommendation = nil
    }

    // MARK: - Demo

    func simulateInactivity() async {
        let now = Date()
        let fakeEvent = InactivityEvent(
            start: now.addingTimeInterval(-TimeInterval(inactivityThresholdMinutes * 60)),
            end: now
        )
        let coordinate = lastKnownCoordinate ?? Coordinate(latitude: 55.6761, longitude: 12.5683)
        await generateRecommendation(for: fakeEvent, at: coordinate)
    }

    // MARK: - Private

    private func handle(_ event: ServiceEvent) async {
        switch event {
        case .inactivityDetected(let inactivity):
            guard let coordinate = lastKnownCoordinate else { return }
            await generateRecommendation(for: inactivity, at: coordinate)
        case .significantLocationChange(let lat, let lon):
            lastKnownCoordinate = Coordinate(latitude: lat, longitude: lon)
        case .locationVisit:
            break
        }
    }

    private func generateRecommendation(for inactivity: InactivityEvent, at coordinate: Coordinate) async {
        do {
            let output = try await useCase.execute(
                inactivity: inactivity,
                currentCoordinate: coordinate,
                inactivityThresholdMinutes: inactivityThresholdMinutes,
                maxDistance: maxDistance,
                searchRadius: searchRadius,
                sentCountToday: sentCountToday,
                lastNotificationSentAt: lastNotificationSentAt,
                shouldScheduleNotification: true,
                now: Date()
            )

            if let reco = output.recommendation {
                recommendation = reco
            }

            if output.didScheduleNotification {
                sentCountToday += 1
                lastNotificationSentAt = Date()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
