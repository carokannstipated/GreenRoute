// Declares the complete SwiftData schema for the GreenRoute persistent store.

import SwiftData

/// Registers all SwiftData entity types that must be present in the same `ModelContainer`.
///
/// All entities must be listed here; omitting any one of them causes SwiftData to fail
/// at container creation time when a relationship or migration references the missing type.
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
