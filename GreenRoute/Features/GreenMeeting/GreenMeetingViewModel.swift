//
//  GreenMeetingViewModel.swift
//  GreenRoute
//
//  Created by Freja Egelund Grønnemose on 14/04/2026.
//
// View model for the Green Meeting feature. Given a desired meeting duration,
// it finds a nearby green area that fits the available walking time and exposes
// it for the map sheet to display.

import Foundation
import GreenRouteDomain
import GreenRouteService

/// Drives the Green Meeting flow: takes a user-specified duration, derives a walking radius,
/// finds the most suitably distanced green area, and triggers the map sheet.
@MainActor
@Observable
final class GreenMeetingViewModel {

    /// True while the map sheet presenting the route is visible.
    var isShowingMap = false
    /// True while the user is actively navigating the meeting route.
    var isWalking = false
    /// True while a green area search is in progress, used to show a loading indicator.
    var isSearching = false
    /// Non-nil when a search or routing step fails; displayed as an alert.
    var errorMessage: String?
    /// The green area selected for the meeting, passed to the map sheet when non-nil.
    var foundGreenArea: GreenArea?

    private let greenAreaProvider: any GreenAreaProvider
    private let locationStore: LocationStore
    /// Average walking speed in metres per second, used to convert duration to distance.
    private let walkingSpeed: Double = 1.4

    /// Exposed to the map view so it can calculate the walking route without going through the service.
    private(set) var routeProvider: any RouteProvider

    init(greenAreaProvider: any GreenAreaProvider, routeProvider: any RouteProvider, locationStore: LocationStore) {
        self.greenAreaProvider = greenAreaProvider
        self.routeProvider = routeProvider
        self.locationStore = locationStore
    }

    /// The user's current position, falling back to central Copenhagen if no location is available yet.
    var currentCoordinate: Coordinate {
        locationStore.lastKnownCoordinate ?? Coordinate(latitude: 55.6761, longitude: 12.5683)
    }

    /// Re-opens the map sheet after the user has dismissed it mid-session.
    func resumeSession() {
        isShowingMap = true
    }

    /// Clears the active session state so the user can start a new meeting.
    func endSession() {
        foundGreenArea = nil
        isShowingMap = false
        isWalking = false
    }

    /// Searches for a green area reachable within half the total meeting duration (the outbound leg).
    /// Picks the area whose distance best matches half the search radius, balancing reach with comfort.
    /// - Parameters:
    ///   - hours: The hours component of the meeting duration entered by the user.
    ///   - minutes: The minutes component of the meeting duration entered by the user.
    func startMeeting(hours: Int, minutes: Int) async {
        let totalSeconds = TimeInterval((hours * 3600) + (minutes * 60))

        // Only the outbound half of the trip is used for distance — the return leg mirrors it.
        let outboundSeconds = totalSeconds / 2
        // Cap search radius at 2 km to avoid surfacing areas too far to walk comfortably.
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

            // Prefer the area whose actual distance is closest to half the search radius,
            // so the walk uses roughly half the available time rather than the full amount.
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
