//
//  SettingsViewModel.swift
//  GreenRoute
//
//  Created by David Rivera on 21/04/2026.
//

import Foundation
import GreenRouteDomain

@MainActor
@Observable
final class SettingsViewModel {

    // MARK: - UI State

    var maxRouteDuration: Int = 15
    var homeAddress: SavedAddress?
    var workAddress: SavedAddress?

    // MARK: - Dependencies

    private let repository: SettingsRepository

    // MARK: - Init

    init(repository: SettingsRepository) {
        self.repository = repository
        load()
    }

    // MARK: - Actions

    func setMaxRouteDuration(_ value: Int) {
        maxRouteDuration = value
        save()
    }

    func setHomeAddress(_ value: SavedAddress?) {
        homeAddress = value
        save()
    }

    func setWorkAddress(_ value: SavedAddress?) {
        workAddress = value
        save()
    }

    // MARK: - Private

    private func save() {
        repository.save(AppSettings(
            maxRouteDurationMinutes: maxRouteDuration,
            homeAddress: homeAddress,
            workAddress: workAddress
        ))
    }

    func reload() {
        load()
    }

    private func load() {
        let settings = repository.load()
        maxRouteDuration = settings.maxRouteDurationMinutes
        homeAddress = settings.homeAddress
        workAddress = settings.workAddress
    }
}
