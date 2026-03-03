//
//  RecommendationEntity.swift
//  GreenRouteData
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import Foundation
import SwiftData

@Model
public final class RecommendationEntity {
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date

    // Trigger
    public var triggerRaw: String

    // Target (GreenArea snapshot)
    public var targetId: String
    public var targetName: String
    public var targetLat: Double
    public var targetLon: Double
    public var targetKindRaw: String

    // Snapshot metrics
    public var distanceMeters: Double
    public var estimatedWalkMinutes: Int

    public init(
        id: UUID,
        createdAt: Date,
        triggerRaw: String,
        targetId: String,
        targetName: String,
        targetLat: Double,
        targetLon: Double,
        targetKindRaw: String,
        distanceMeters: Double,
        estimatedWalkMinutes: Int
    ) {
        self.id = id
        self.createdAt = createdAt
        self.triggerRaw = triggerRaw
        self.targetId = targetId
        self.targetName = targetName
        self.targetLat = targetLat
        self.targetLon = targetLon
        self.targetKindRaw = targetKindRaw
        self.distanceMeters = distanceMeters
        self.estimatedWalkMinutes = estimatedWalkMinutes
    }
}
