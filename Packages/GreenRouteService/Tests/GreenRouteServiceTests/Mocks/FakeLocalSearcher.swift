//
//  FakeLocalSearcher.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 17/03/2026.
//

import GreenRouteDomain
@testable import GreenRouteService

actor FakeLocalSearcher: LocalSearching {

    private var stubbedResults: [LocalSearchResult] = []
    private var stubbedError: Error?
    private(set) var callCount = 0
    private(set) var lastCoordinate: Coordinate?
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
