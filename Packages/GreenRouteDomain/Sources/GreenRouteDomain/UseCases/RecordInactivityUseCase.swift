// Thin use case that persists an inactivity event, keeping call sites decoupled from the repository.

import Foundation

/// Saves a single `InactivityEvent` to persistent storage.
///
/// Exists as a use case rather than a direct repository call so that higher-level
/// code depends on this named boundary rather than `InactivityEventRepository` directly,
/// making it easier to add pre/post-save behaviour (e.g. analytics) in one place.
public struct RecordInactivityEventUseCase: Sendable {

    private let repository: InactivityEventRepository

    public init(repository: InactivityEventRepository) {
        self.repository = repository
    }

    /// Persists `event` to the inactivity repository.
    public func execute(_ event: InactivityEvent) async throws {
        try await repository.save(event)
    }
}
