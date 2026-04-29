//
//  RecommendationEngine.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import Foundation

public struct RecommendationEngine: Sendable {

    public init() {}

    // Rule-based v1:
    // IF inactivity >= threshold AND nearest green area within maxDistance
    // THEN generate a Recommendation.
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
        /*
        guard inactivity.duration >= thresholdSeconds else { return nil }

        // Find nearest green area
        guard let nearest = nearbyGreenAreas.min(by: {
            currentCoordinate.distance(to: $0.coordinate) < currentCoordinate.distance(to: $1.coordinate)
        }) else {
            return nil
        }

        let distanceValue = currentCoordinate.distance(to: nearest.coordinate)
        let distance = DistanceMeters(value: distanceValue)

        guard distance <= maxDistance else { return nil }
         */
        
        #if DEBUG
        print("🟡 inactivity duration: \(inactivity.duration), threshold: \(thresholdSeconds)")
        #endif
        guard inactivity.duration >= thresholdSeconds else {
            #if DEBUG
            print("🔴 rejected: inactivity duration too short")
            #endif
            return nil
        }

        guard let nearest = nearbyGreenAreas.min(by: {
            currentCoordinate.distance(to: $0.coordinate) < currentCoordinate.distance(to: $1.coordinate)
        }) else {
            #if DEBUG
            print("🔴 rejected: no nearby areas")
            #endif
            return nil
        }

        let distanceValue = currentCoordinate.distance(to: nearest.coordinate)
        let distance = DistanceMeters(value: distanceValue)
        #if DEBUG
        print("🟡 nearest: \(nearest.name), distance: \(distanceValue), maxDistance: \(maxDistance.value)")
        #endif

        guard distance <= maxDistance else {
            #if DEBUG
            print("🔴 rejected: too far")
            #endif
            return nil
        }

        // Estimate walk time (rounded to nearest minute, minimum 1 minute if distance > 0)
        let seconds = distance.value / assumedWalkingSpeedMetersPerSecond
        var minutes = Int((seconds / 60.0).rounded())

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
