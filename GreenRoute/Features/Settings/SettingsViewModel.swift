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

    var maxRouteDuration: Int = 15
    var homeAddress: SavedAddress?
    var workAddress: SavedAddress?

    private let repository: SettingsRepository


    init(repository: SettingsRepository) {
        self.repository = repository
        load()
    }


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
