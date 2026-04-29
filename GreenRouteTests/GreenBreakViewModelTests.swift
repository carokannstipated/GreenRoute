//
//  GreenBreakViewModelTests.swift
//  GreenRoute
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//


import XCTest
import GreenRouteDomain
@testable import GreenRoute
@testable import GreenRouteService

@MainActor
final class GreenBreakViewModelTests: XCTestCase {

    func test_start_startsService() async {
        let (viewModel, service, _) = makeSUT()
        await viewModel.start()
        XCTAssertEqual(service.startCallCount, 1)
    }

    func test_stop_stopsService() async {
        let (viewModel, service, _) = makeSUT()
        await viewModel.start()
        await viewModel.stop()
        XCTAssertEqual(service.stopCallCount, 1)
    }

    func test_significantLocationChange_updatesLastKnownCoordinate() async throws {
        let (viewModel, service, _) = makeSUT()
        await viewModel.start()

        service.emit(.significantLocationChange(latitude: 55.676, longitude: 12.568))
        
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(viewModel.lastKnownCoordinate?.latitude, 55.676)
        XCTAssertEqual(viewModel.lastKnownCoordinate?.longitude, 12.568)
    }

    func test_inactivityDetected_withNoCoordinate_doesNotSetRecommendation() async throws {
        let (viewModel, service, provider) = makeSUT()
        provider.stubbedAreas = [makeGreenArea()]
        await viewModel.start()

        service.emit(.inactivityDetected(makeInactivityEvent()))
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertNil(viewModel.recommendation)
    }

    func test_inactivityDetected_withCoordinate_setsRecommendation() async throws {
        let (viewModel, service, provider) = makeSUT()
        provider.stubbedAreas = [makeGreenArea(distance: 200)]
        await viewModel.start()

        service.emit(.significantLocationChange(latitude: 55.6761, longitude: 12.5683))
        try await Task.sleep(for: .milliseconds(50))

        service.emit(.inactivityDetected(makeInactivityEvent(durationMinutes: 25)))
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertNotNil(viewModel.recommendation)
    }

    func test_acceptRecommendation_setsIsShowingMapTrue() async throws {
        let (viewModel, _, _) = makeSUT()
        await viewModel.simulateInactivity()
        try await Task.sleep(for: .milliseconds(100))

        viewModel.acceptRecommendation()
        XCTAssertTrue(viewModel.isShowingMap)
    }

    func test_dismissRecommendation_clearsRecommendation() async throws {
        let (viewModel, _, provider) = makeSUT()
        provider.stubbedAreas = [makeGreenArea(distance: 200)]
        await viewModel.simulateInactivity()
        try await Task.sleep(for: .milliseconds(100))

        viewModel.dismissRecommendation()
        XCTAssertNil(viewModel.recommendation)
    }


    private typealias SUT = (
        viewModel: GreenBreakViewModel,
        service: FakeGreenRouteService,
        provider: FakeGreenAreaProvider
    )

    private func makeSUT() -> SUT {
        let service = FakeGreenRouteService()
        let provider = FakeGreenAreaProvider()
        let repository = FakeRecommendationRepository()
        let scheduler = FakeNotificationScheduler()

        service.greenAreaProvider = provider
        service.notificationScheduler = scheduler

        let useCase = GenerateGreenBreakUseCase(
            greenAreaProvider: provider,
            recommendationEngine: RecommendationEngine(),
            recommendationRepository: repository,
            notificationPolicy: NotificationPolicy(maxPerDay: 2, minimumInterval: 0),
            notificationScheduler: scheduler
        )

        let viewModel = GreenBreakViewModel(service: service, useCase: useCase)
        return (viewModel, service, provider)
    }

    private func makeGreenArea(distance: Double = 200) -> GreenArea {
        GreenArea(
            id: "park-1",
            name: "Fælledparken",
            coordinate: Coordinate(latitude: 55.6761 + (distance / 111_000), longitude: 12.5683),
            kind: .park
        )
    }

    private func makeInactivityEvent(durationMinutes: Int = 25) -> InactivityEvent {
        let end = Date()
        let start = end.addingTimeInterval(-TimeInterval(durationMinutes * 60))
        return InactivityEvent(start: start, end: end)
    }
}
