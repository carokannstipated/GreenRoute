//
//  GreenMeetingViewModel.swift
//  GreenRoute
//
//  Created by Freja Egelund Grønnemose on 14/04/2026.
//


import Foundation
import GreenRouteDomain
import GreenRouteService

@MainActor
@Observable
final class GreenMeetingViewModel {

    var isShowingMap = false
    var isSearching = false
    var errorMessage: String?
    var foundGreenArea: GreenArea?

    private let greenAreaProvider: any GreenAreaProvider
    private let locationStore: LocationStore
    private let walkingSpeed: Double = 1.4

    private(set) var routeProvider: any RouteProvider

    init(greenAreaProvider: any GreenAreaProvider, routeProvider: any RouteProvider, locationStore: LocationStore) {
        self.greenAreaProvider = greenAreaProvider
        self.routeProvider = routeProvider
        self.locationStore = locationStore
    }

    var currentCoordinate: Coordinate {
        locationStore.lastKnownCoordinate ?? Coordinate(latitude: 55.6761, longitude: 12.5683)
    }

    func startMeeting(hours: Int, minutes: Int) async {
        let totalSeconds = TimeInterval((hours * 3600) + (minutes * 60))

        // Outbound leg is half the total time
        let outboundSeconds = totalSeconds / 2
        // Cap search radius at 2km to stay practical
        let searchRadius = DistanceMeters(value: min(outboundSeconds * walkingSpeed, 2000))

        isSearching = true
        defer { isSearching = false }

        do {
            let areas = try await greenAreaProvider.fetchGreenAreas(
                near: currentCoordinate,
                radius: searchRadius
            )

            guard !areas.isEmpty else {
                errorMessage = "No green areas found nearby. Try a longer duration."
                return
            }

            // Prefer the area closest to the ideal halfway distance
            let idealDistance = searchRadius.value / 2
            foundGreenArea = areas.min(by: { a, b in
                let distA = abs(currentCoordinate.distance(to: a.coordinate) - idealDistance)
                let distB = abs(currentCoordinate.distance(to: b.coordinate) - idealDistance)
                return distA < distB
            })

            isShowingMap = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
