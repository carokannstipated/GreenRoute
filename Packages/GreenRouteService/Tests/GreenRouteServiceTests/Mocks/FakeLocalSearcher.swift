// Test double for LocalSearching that returns configurable stub results or errors
// and records the arguments passed to each search call.

import GreenRouteDomain
@testable import GreenRouteService

/// Allows tests to configure canned results or errors for `search(near:radius:)` and
/// to inspect the coordinate/radius values passed by the caller.
actor FakeLocalSearcher: LocalSearching {

    /// Results returned by the next `search` call; empty by default.
    private var stubbedResults: [LocalSearchResult] = []

    /// When non-nil, `search` throws this error instead of returning results.
    private var stubbedError: Error?

    /// Total number of times `search(near:radius:)` has been called.
    private(set) var callCount = 0

    /// The coordinate argument from the most recent `search` call.
    private(set) var lastCoordinate: Coordinate?

    /// The radius argument from the most recent `search` call.
    private(set) var lastRadius: DistanceMeters?

    func setStubbedResults(_ results: [LocalSearchResult]) {
        stubbedResults = results
    }

    func setStubbedError(_ error: Error?) {
        stubbedError = error
    }

    func search(near coordinate: Coordinate, radius: DistanceMeters) async throws -> [LocalSearchResult] {
        callCount += 1
        lastCoordinate = coordinate
        lastRadius = radius
        if let error = stubbedError { throw error }
        return stubbedResults
    }
}
