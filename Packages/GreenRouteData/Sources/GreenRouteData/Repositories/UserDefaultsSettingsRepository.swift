//
//  UserDefaultsSettingsRepository.swift
//  GreenRouteData
//
//  Created by David Rivera on 14/04/2026.
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

        if let data = defaults.data(forKey: key("homeAddress")),
           let address = try? JSONDecoder().decode(SavedAddress.self, from: data) {
            settings.homeAddress = address
        }

        if let data = defaults.data(forKey: key("workAddress")),
           let address = try? JSONDecoder().decode(SavedAddress.self, from: data) {
            settings.workAddress = address
        }

        return settings
    }

    public func save(_ settings: AppSettings) {
        defaults.set(settings.maxRouteDurationMinutes, forKey: key("maxRouteDurationMinutes"))

        if let data = try? JSONEncoder().encode(settings.homeAddress) {
            defaults.set(data, forKey: key("homeAddress"))
        } else {
            defaults.removeObject(forKey: key("homeAddress"))
        }

        if let data = try? JSONEncoder().encode(settings.workAddress) {
            defaults.set(data, forKey: key("workAddress"))
        } else {
            defaults.removeObject(forKey: key("workAddress"))
        }
    }

    private func key(_ name: String) -> String {
        "\(prefix)\(name)"
    }
}
