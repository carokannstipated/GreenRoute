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
        RecommendationEntity.self,
        LocationVisitEntity.self,
        GreenAreaEntity.self,
        RecommendationDecisionEntity.self,
        RecurringPatternEntity.self
    ])
}
