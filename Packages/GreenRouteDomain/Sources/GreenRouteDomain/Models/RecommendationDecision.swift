//
//  RecommendationDecision.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import Foundation

public struct RecommendationDecision: Equatable, Hashable, Sendable, Identifiable {
    
    public enum Decision: Equatable, Hashable, Sendable {
        case accepted
        case dismissed
        case ignored
    }
    
    public let id: UUID
    public let recommendationID: UUID
    public let decision: Decision
    public let timestamp: Date
    
    public init(id: UUID = UUID(), recommendationID: UUID, decision: Decision, timestamp: Date) {
        self.id = id
        self.recommendationID = recommendationID
        self.decision = decision
        self.timestamp = timestamp
    }
}
