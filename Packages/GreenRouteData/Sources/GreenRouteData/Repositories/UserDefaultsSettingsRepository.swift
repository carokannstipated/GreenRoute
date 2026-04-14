//
//  UserDefaultsSettingsRepository.swift
//  GreenRouteData
// Created by David Rivera on 14/04/2026.
//

import Foundation
import GreenRouteDomain

public final class UserDefaultsSettingsRepository: SettingsRepository, @unchecked Sendable {

    private let defaults: UserDefaults
    private let prefix = "gr_settings_"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> AppSettings {
        var settings = AppSettings.default

        if let value = defaults.object(forKey: key("maxRouteDurationMinutes")) as? Int {
            settings.maxRouteDurationMinutes = value
        }

        // Load new settings here as they are added to AppSettings

        return settings
    }

    public func save(_ settings: AppSettings) {
        defaults.set(settings.maxRouteDurationMinutes, forKey: key("maxRouteDurationMinutes"))

        // Save new settings here as they are added to AppSettings
    }

    private func key(_ name: String) -> String {
        "\(prefix)\(name)"
    }
}
