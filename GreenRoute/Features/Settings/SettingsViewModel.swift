//
//  SettingsViewModel.swift
//  GreenRoute
//
//  Created by David Rivera on 21/04/2026.
//
// View model for the Settings feature. Owns all user-configurable preferences and
// persists them through a SettingsRepository whenever a value changes.

import Foundation
import GreenRouteDomain

/// Manages user-configurable app settings, bridging the UI and the persistence layer.
/// Each setter immediately persists the full settings snapshot so no manual save step is needed.
@MainActor
@Observable
final class SettingsViewModel {

    /// Maximum allowed walking route duration shown in Route Preferences, in minutes.
    var maxRouteDuration: Int = 15
    /// The user's saved home address, used as a familiar starting point for routes.
    var homeAddress: SavedAddress?
    /// The user's saved work address, used as a familiar destination for routes.
    var workAddress: SavedAddress?

    private let repository: SettingsRepository

    /// Loads persisted settings immediately on creation so the view always reflects stored values.
    init(repository: SettingsRepository) {
        self.repository = repository
        load()
    }

    /// Updates the max route duration and persists the change.
    func setMaxRouteDuration(_ value: Int) {
        maxRouteDuration = value
        save()
    }

    /// Updates the home address and persists the change. Pass nil to clear the saved address.
    func setHomeAddress(_ value: SavedAddress?) {
        homeAddress = value
        save()
    }

    /// Updates the work address and persists the change. Pass nil to clear the saved address.
    func setWorkAddress(_ value: SavedAddress?) {
        workAddress = value
        save()
    }

    /// Re-reads settings from the repository. Called when the view re-appears to pick up
    /// any changes made from another screen (e.g. route duration changed via GreenBreakView's stepper).
    func reload() {
        load()
    }

    /// Builds and writes the current state as an AppSettings snapshot.
    private func save() {
        repository.save(AppSettings(
            maxRouteDurationMinutes: maxRouteDuration,
            homeAddress: homeAddress,
            workAddress: workAddress
        ))
    }

    /// Reads the stored settings and applies them to the observable properties.
    private func load() {
        let settings = repository.load()
        maxRouteDuration = settings.maxRouteDurationMinutes
        homeAddress = settings.homeAddress
        workAddress = settings.workAddress
    }
}
