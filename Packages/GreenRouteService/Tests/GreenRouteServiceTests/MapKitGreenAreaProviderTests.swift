//
//  MapKitGreenAreaProviderTests.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//

import XCTest
import MapKit
import GreenRouteDomain
@testable import GreenRouteService

final class MapKitGreenAreaProviderTests: XCTestCase {

    // MARK: - Results mapping

    func test_returnsOneGreenAreaPerSearchResult() async throws {
        let (provider, searcher) = makeSUT()
        await searcher.setStubbedResults([
            makeResult(name: "Fælledparken", category: .park),
            makeResult(name: "Amager Strand", category: .beach)
        ])

        let results = try await provider.fetchGreenAreas(near: defaultCoordinate, radius: defaultRadius)

        XCTAssertEqual(results.count, 2)
    }

    func test_returnsEmptyArrayWhenNoResults() async throws {
        let (provider, _) = makeSUT()

        let results = try await provider.fetchGreenAreas(near: defaultCoordinate, radius: defaultRadius)

        XCTAssertTrue(results.isEmpty)
    }

    func test_preservesNameFromSearchResult() async throws {
        let (provider, searcher) = makeSUT()
        await searcher.setStubbedResults([makeResult(name: "Ørstedsparken", category: .park)])

        let result = try await provider.fetchGreenAreas(near: defaultCoordinate, radius: defaultRadius)

        XCTAssertEqual(result.first?.name, "Ørstedsparken")
    }

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

    func test_mapsParkCategoryTopark() async throws {
        let kind = try await kindFor(category: .park)
        XCTAssertEqual(kind, .park)
    }

    func test_mapsBeachCategoryToBeach() async throws {
        let kind = try await kindFor(category: .beach)
        XCTAssertEqual(kind, .beach)
    }

    func test_mapsNationalParkToNatureReserve() async throws {
        let kind = try await kindFor(category: .nationalPark)
        XCTAssertEqual(kind, .natureReserve)
    }

    func test_mapsNilCategoryToOther() async throws {
        let kind = try await kindFor(category: nil)
        XCTAssertEqual(kind, .other)
    }

    // MARK: - Pass-through behaviour

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

    func test_propagatesSearchError() async throws {
        let (provider, searcher) = makeSUT()
        await searcher.setStubbedError(URLError(.notConnectedToInternet))

        do {
            _ = try await provider.fetchGreenAreas(near: defaultCoordinate, radius: defaultRadius)
            XCTFail("Expected error to be thrown")
        } catch {
            // pass
        }
    }

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
