//
//  InactivityEventRepository.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import Foundation

// MARK: - Inactivity

public protocol InactivityEventRepository: Sendable {
    func save(_ event: InactivityEvent) async throws
    func fetch(from start: Date, to end: Date) async throws -> [InactivityEvent]
}

// MARK: - Location visits

public protocol LocationVisitRepository: Sendable {
    func save(_ visit: LocationVisit) async throws
    func fetch(from start: Date, to end: Date) async throws -> [LocationVisit]
}

// MARK: - Recommendations

public protocol RecommendationRepository: Sendable {
    func save(_ recommendation: Recommendation) async throws
    func fetch(from start: Date, to end: Date) async throws -> [Recommendation]
}

// MARK: - Decisions (optional)

public protocol RecommendationDecisionRepository: Sendable {
    func save(_ decision: RecommendationDecision) async throws
    func fetch(for recommendationId: UUID) async throws -> [RecommendationDecision]
}

// MARK: - Patterns

public protocol RecurringPatternRepository: Sendable {
    func save(_ pattern: RecurringPattern) async throws
    func fetchLatest() async throws -> RecurringPattern?
}

public protocol GreenAreaRepository: Sendable {
    func save(_ greenArea: GreenArea) async throws
    func fetchAll() async throws -> [GreenArea]
}

// MARK: - Settings

public protocol SettingsRepository: Sendable {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}
