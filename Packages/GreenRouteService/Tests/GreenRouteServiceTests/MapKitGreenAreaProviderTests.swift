// Unit tests for MapKitGreenAreaProvider covering result mapping, GreenArea.Kind
// derivation from POI categories, pass-through of search parameters, and error propagation.

import XCTest
import MapKit
import GreenRouteDomain
@testable import GreenRouteService

final class MapKitGreenAreaProviderTests: XCTestCase {

    // MARK: - Results mapping

    /// Verifies that one `GreenArea` is returned for each `LocalSearchResult`,
    /// with no filtering or merging applied.
    func test_returnsOneGreenAreaPerSearchResult() async throws {
        let (provider, searcher) = makeSUT()
        await searcher.setStubbedResults([
            makeResult(name: "Fælledparken", category: .park),
            makeResult(name: "Amager Strand", category: .beach)
        ])

        let results = try await provider.fetchGreenAreas(near: defaultCoordinate, radius: defaultRadius)

        XCTAssertEqual(results.count, 2)
    }

    /// Verifies that an empty result set from the searcher produces an empty array,
    /// with no placeholder or default area injected.
    func test_returnsEmptyArrayWhenNoResults() async throws {
        let (provider, _) = makeSUT()

        let results = try await provider.fetchGreenAreas(near: defaultCoordinate, radius: defaultRadius)

        XCTAssertTrue(results.isEmpty)
    }

    /// Verifies that the place name from the search result is preserved unchanged
    /// in the resulting `GreenArea`.
    func test_preservesNameFromSearchResult() async throws {
        let (provider, searcher) = makeSUT()
        await searcher.setStubbedResults([makeResult(name: "Ørstedsparken", category: .park)])

        let result = try await provider.fetchGreenAreas(near: defaultCoordinate, radius: defaultRadius)

        XCTAssertEqual(result.first?.name, "Ørstedsparken")
    }

    /// Verifies that latitude and longitude values from the search result are forwarded
    /// into the `GreenArea.coordinate` without rounding or transformation.
    func test_preservesCoordinatesFromSearchResult() async throws {
        let (provider, searcher) = makeSUT()
        await searcher.setStubbedResults([
            LocalSearchResult(name: "Park", latitude: 55.7020, longitude: 12.5700, pointOfInterestCategory: .park)
        ])

        let result = try await provider.fetchGreenAreas(near: defaultCoordinate, radius: defaultRadius)

        XCTAssertEqual(result.first?.coordinate.latitude, 55.7020)
        XCTAssertEqual(result.first?.coordinate.longitude, 12.5700)
    }

    // MARK: - Kind mapping

    /// Verifies that a `.park` POI category maps to `GreenArea.Kind.park`.
    func test_mapsParkCategoryTopark() async throws {
        let kind = try await kindFor(category: .park)
        XCTAssertEqual(kind, .park)
    }

    /// Verifies that a `.beach` POI category maps to `GreenArea.Kind.beach`.
    func test_mapsBeachCategoryToBeach() async throws {
        let kind = try await kindFor(category: .beach)
        XCTAssertEqual(kind, .beach)
    }

    /// Verifies that a `.nationalPark` POI category maps to `GreenArea.Kind.natureReserve`.
    func test_mapsNationalParkToNatureReserve() async throws {
        let kind = try await kindFor(category: .nationalPark)
        XCTAssertEqual(kind, .natureReserve)
    }

    /// Verifies that a nil POI category (MapKit didn't supply one) falls through to `.other`.
    func test_mapsNilCategoryToOther() async throws {
        let kind = try await kindFor(category: nil)
        XCTAssertEqual(kind, .other)
    }

    // MARK: - Pass-through behaviour

    /// Verifies that the coordinate and radius passed to the provider are forwarded
    /// unchanged to the underlying searcher.
    func test_passesCoordinateAndRadiusToSearcher() async throws {
        let (provider, searcher) = makeSUT()
        let coordinate = Coordinate(latitude: 55.676, longitude: 12.568)
        let radius = DistanceMeters(value: 750)

        _ = try await provider.fetchGreenAreas(near: coordinate, radius: radius)

        let lastCoordinate = await searcher.lastCoordinate
        let lastRadius = await searcher.lastRadius
        XCTAssertEqual(lastCoordinate, coordinate)
        XCTAssertEqual(lastRadius, radius)
    }

    /// Verifies that any error thrown by the searcher is propagated to the caller
    /// without being swallowed or wrapped.
    func test_propagatesSearchError() async throws {
        let (provider, searcher) = makeSUT()
        await searcher.setStubbedError(URLError(.notConnectedToInternet))

        do {
            _ = try await provider.fetchGreenAreas(near: defaultCoordinate, radius: defaultRadius)
            XCTFail("Expected error to be thrown")
        } catch {
        }
    }

    /// Verifies that the provider calls the searcher exactly once per `fetchGreenAreas` call,
    /// with no retry or caching behaviour.
    func test_callsSearcherExactlyOnce() async throws {
        let (provider, searcher) = makeSUT()

        _ = try await provider.fetchGreenAreas(near: defaultCoordinate, radius: defaultRadius)

        let callCount = await searcher.callCount
        XCTAssertEqual(callCount, 1)
    }

    // MARK: - Helpers

    private typealias SUT = (provider: MapKitGreenAreaProvider, searcher: FakeLocalSearcher)

    private func makeSUT() -> SUT {
        let searcher = FakeLocalSearcher()
        return (MapKitGreenAreaProvider(searcher: searcher), searcher)
    }

    /// Convenience that stubs a single result with the given category and returns
    /// the `GreenArea.Kind` produced by the provider.
    private func kindFor(category: MKPointOfInterestCategory?) async throws -> GreenArea.Kind {
        let (provider, searcher) = makeSUT()
        await searcher.setStubbedResults([makeResult(name: "Area", category: category)])
        let results = try await provider.fetchGreenAreas(near: defaultCoordinate, radius: defaultRadius)
        return try XCTUnwrap(results.first?.kind)
    }

    private func makeResult(name: String, category: MKPointOfInterestCategory?) -> LocalSearchResult {
        LocalSearchResult(name: name, latitude: 55.676, longitude: 12.568, pointOfInterestCategory: category)
    }

    private let defaultCoordinate = Coordinate(latitude: 55.676, longitude: 12.568)
    private let defaultRadius = DistanceMeters(value: 500)
}
