// Pure stateless engine that decides whether to issue a green-break recommendation.

import Foundation

/// Evaluates inactivity and proximity to produce a `Recommendation`, or `nil` when
/// the conditions for a recommendation are not met.
///
/// The engine is stateless and `Sendable`; all decision inputs are passed explicitly.
/// It applies three successive filters: inactivity threshold → nearest green area exists →
/// nearest green area is within the allowed distance.
public struct RecommendationEngine: Sendable {

    public init() {}

    /// Evaluates whether current conditions warrant a green-break recommendation.
    ///
    /// - Parameters:
    ///   - inactivity: The detected inactivity period that triggered this evaluation.
    ///   - currentCoordinate: The user's current position used for distance calculations.
    ///   - nearbyGreenAreas: Candidate areas pre-filtered by the caller's search radius.
    ///   - inactivityThresholdMinutes: Minimum inactivity duration (minutes) required to proceed.
    ///   - maxDistance: Maximum allowed straight-line distance to the recommended area.
    ///   - assumedWalkingSpeedMetersPerSecond: Walking speed used to estimate travel time; defaults to 1.4 m/s (≈ 5 km/h).
    ///   - createdAt: Timestamp to embed in the recommendation (typically `now`).
    ///   - trigger: What initiated this call; defaults to `.inactivity`.
    /// - Returns: A `Recommendation` if all conditions are met, or `nil` if any filter rejects.
    public func generateRecommendation(
        inactivity: InactivityEvent,
        currentCoordinate: Coordinate,
        nearbyGreenAreas: [GreenArea],
        inactivityThresholdMinutes: Int,
        maxDistance: DistanceMeters,
        assumedWalkingSpeedMetersPerSecond: Double = 1.4,
        createdAt: Date,
        trigger: Recommendation.Trigger = .inactivity
    ) -> Recommendation? {

        precondition(inactivityThresholdMinutes >= 0, "inactivityThresholdMinutes cannot be negative")
        precondition(assumedWalkingSpeedMetersPerSecond > 0, "assumedWalkingSpeedMetersPerSecond must be > 0")

        let thresholdSeconds = TimeInterval(inactivityThresholdMinutes * 60)

        #if DEBUG
        print("inactivity duration: \(inactivity.duration), threshold: \(thresholdSeconds)")
        #endif

        // Filter 1: user must have been inactive long enough.
        guard inactivity.duration >= thresholdSeconds else {
            #if DEBUG
            print("rejected: inactivity duration too short")
            #endif
            return nil
        }

        // Filter 2: at least one candidate green area must exist.
        guard let nearest = nearbyGreenAreas.min(by: {
            currentCoordinate.distance(to: $0.coordinate) < currentCoordinate.distance(to: $1.coordinate)
        }) else {
            #if DEBUG
            print("rejected: no nearby areas")
            #endif
            return nil
        }

        let distanceValue = currentCoordinate.distance(to: nearest.coordinate)
        let distance = DistanceMeters(value: distanceValue)
        #if DEBUG
        print("nearest: \(nearest.name), distance: \(distanceValue), maxDistance: \(maxDistance.value)")
        #endif

        // Filter 3: the nearest area must be within the configured maximum distance.
        guard distance <= maxDistance else {
            #if DEBUG
            print("rejected: too far")
            #endif
            return nil
        }

        let seconds = distance.value / assumedWalkingSpeedMetersPerSecond
        var minutes = Int((seconds / 60.0).rounded())

        // Ensure any non-zero distance shows at least 1 minute so notifications
        // never display "0 min walk" for a very close but non-zero distance.
        if distance.value > 0, minutes == 0 { minutes = 1 }

        return Recommendation(
            createdAt: createdAt,
            trigger: trigger,
            target: nearest,
            distance: distance,
            estimatedWalkMinutes: minutes
        )
    }
}
