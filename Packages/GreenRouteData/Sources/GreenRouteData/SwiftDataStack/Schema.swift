//
//  Schema.swift
//  GreenRouteData
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import SwiftData

public enum GreenRouteSchema {
    public static let schema = Schema([
        InactivityEventEntity.self,
        RecommendationEntity.self
        // senere: LocationVisitEntity.self, RecurringPatternEntity.self, RecommendationDecisionEntity.self
    ])
}
