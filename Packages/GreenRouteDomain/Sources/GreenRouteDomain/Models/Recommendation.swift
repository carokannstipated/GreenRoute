//
//  Recommendation.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import Foundation

public struct Recommendation: Equatable, Hashable, Sendable, Identifiable {
    
    public enum Trigger: Equatable, Hashable, Sendable {
        case inactivity
        case pattern
        case userRequested
    }
    
    public let id: UUID
    public let createdAt: Date
    
    // Why this recommendation was created
    public let trigger: Trigger
    
    // The suggested green destination
    public let target: GreenArea
    
    // Distance from user's current location at creation time.
    public let distance: DistanceMeters
    
    // Estimated walk time (rounded minutes) at creation time
    public let estimatedWalkMinutes: Int
    
    public init(id: UUID = UUID(), createdAt: Date, trigger: Trigger, target: GreenArea, distance: DistanceMeters, estimatedWalkMinutes: Int) {
        precondition(estimatedWalkMinutes >= 0, "estimatedWalkMinutes cannot be negative")
        self.id = id
        self.createdAt = createdAt
        self.trigger = trigger
        self.target = target
        self.distance = distance
        self.estimatedWalkMinutes = estimatedWalkMinutes
    }
}
