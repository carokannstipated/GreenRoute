// Integration-style tests for GreenBreakViewModel. Uses fake collaborators throughout
// so tests run without networking, CoreLocation, or CoreMotion.

import XCTest
import GreenRouteDomain
@testable import GreenRoute
@testable import GreenRouteService

@MainActor
final class GreenBreakViewModelTests: XCTestCase {

    // MARK: - Service lifecycle

    /// start() must call through to the underlying service so background monitoring begins.
    func test_start_startsService() async {
        let (viewModel, service, _) = makeSUT()
        await viewModel.start()
        XCTAssertEqual(service.startCallCount, 1)
    }

    /// stop() must call through to the underlying service so resources are released.
    func test_stop_stopsService() async {
        let (viewModel, service, _) = makeSUT()
        await viewModel.start()
        await viewModel.stop()
        XCTAssertEqual(service.stopCallCount, 1)
    }

    // MARK: - Location updates

    /// A significantLocationChange event must update lastKnownCoordinate so future
    /// recommendation searches use the correct position.
    func test_significantLocationChange_updatesLastKnownCoordinate() async throws {
        let (viewModel, service, _) = makeSUT()
        await viewModel.start()

        service.emit(.significantLocationChange(latitude: 55.676, longitude: 12.568))

        // Allow the async event handler to execute before asserting.
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(viewModel.lastKnownCoordinate?.latitude, 55.676)
        XCTAssertEqual(viewModel.lastKnownCoordinate?.longitude, 12.568)
    }

    // MARK: - Inactivity detection

    /// Without a known location, an inactivity event must not produce a recommendation —
    /// the use case requires a coordinate to search for green areas.
    func test_inactivityDetected_withNoCoordinate_doesNotSetRecommendation() async throws {
        let (viewModel, service, provider) = makeSUT()
        provider.stubbedAreas = [makeGreenArea()]
        await viewModel.start()

        service.emit(.inactivityDetected(makeInactivityEvent()))
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertNil(viewModel.recommendation)
    }

    /// When a location is known and a green area is available, an inactivity event
    /// should produce a non-nil recommendation displayed to the user.
    func test_inactivityDetected_withCoordinate_setsRecommendation() async throws {
        let (viewModel, service, provider) = makeSUT()
        provider.stubbedAreas = [makeGreenArea(distance: 200)]
        await viewModel.start()

        // First establish a known location.
        service.emit(.significantLocationChange(latitude: 55.6761, longitude: 12.5683))
        try await Task.sleep(for: .milliseconds(50))

        // Then simulate inactivity to trigger a recommendation.
        service.emit(.inactivityDetected(makeInactivityEvent(durationMinutes: 25)))
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertNotNil(viewModel.recommendation)
    }

    // MARK: - User actions

    /// Accepting a recommendation must show the map sheet so the user can start the route.
    func test_acceptRecommendation_setsIsShowingMapTrue() async throws {
        let (viewModel, _, _) = makeSUT()
        await viewModel.simulateInactivity()
        try await Task.sleep(for: .milliseconds(100))

        viewModel.acceptRecommendation()
        XCTAssertTrue(viewModel.isShowingMap)
    }

    /// Dismissing a recommendation must clear it so the view returns to the idle state.
    func test_dismissRecommendation_clearsRecommendation() async throws {
        let (viewModel, _, provider) = makeSUT()
        provider.stubbedAreas = [makeGreenArea(distance: 200)]
        await viewModel.simulateInactivity()
        try await Task.sleep(for: .milliseconds(100))

        viewModel.dismissRecommendation()
        XCTAssertNil(viewModel.recommendation)
    }

    // MARK: - Helpers

    private typealias SUT = (
        viewModel: GreenBreakViewModel,
        service: FakeGreenRouteService,
        provider: FakeGreenAreaProvider
    )

    /// Builds a complete SUT with permissive notification policy (no daily cap, no minimum interval)
    /// so tests don't need to worry about throttling.
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

    /// Creates a GreenArea at a given distance (in metres) north of the default test coordinate.
    private func makeGreenArea(distance: Double = 200) -> GreenArea {
        GreenArea(
            id: "park-1",
            name: "Fælledparken",
            coordinate: Coordinate(latitude: 55.6761 + (distance / 111_000), longitude: 12.5683),
            kind: .park
        )
    }

    /// Creates an InactivityEvent ending now with the given duration.
    private func makeInactivityEvent(durationMinutes: Int = 25) -> InactivityEvent {
        let end = Date()
        let start = end.addingTimeInterval(-TimeInterval(durationMinutes * 60))
        return InactivityEvent(start: start, end: end)
    }
}
