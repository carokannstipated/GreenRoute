// SwiftData entity for persisting a Recommendation domain model.

import Foundation
import SwiftData

/// Persistent storage representation of a `Recommendation`.
///
/// The recommended `GreenArea` (the `target`) is denormalised into flat scalar fields
/// (`targetId`, `targetName`, `targetLat`, `targetLon`, `targetKindRaw`) because SwiftData
/// cannot store an arbitrary nested model type inline. `RecommendationMapper` reconstructs
/// the `GreenArea` value on read.
@Model
public final class RecommendationEntity {
    /// Unique identifier. The `.unique` attribute enforces upsert semantics.
    @Attribute(.unique) public var id: UUID
    public var createdAt: Date

    /// Raw string representation of `Recommendation.Trigger` (e.g. "inactivity", "pattern").
    public var triggerRaw: String

    /// Denormalised fields for the recommended green area.
    public var targetId: String
    public var targetName: String
    public var targetLat: Double
    public var targetLon: Double
    /// Raw string representation of `GreenArea.Kind` for the target area.
    public var targetKindRaw: String

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
