//
//  RecommendationDecisionEntity.swift
//  GreenRouteData
//
//  Created by David Rivera on 17/03/2026.
//


import Foundation
import SwiftData

@Model
public final class RecommendationDecisionEntity {

    @Attribute(.unique) public var id: UUID
    public var recommendationID: UUID
    public var decisionRaw: String
    public var timestamp: Date

    public init(
        id: UUID,
        recommendationID: UUID,
        decisionRaw: String,
        timestamp: Date
    ) {
        self.id = id
        self.recommendationID = recommendationID
        self.decisionRaw = decisionRaw
        self.timestamp = timestamp
    }
}