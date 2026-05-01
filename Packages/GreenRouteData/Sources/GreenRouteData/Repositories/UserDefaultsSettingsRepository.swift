
// UserDefaults-backed implementation of SettingsRepository.

import Foundation
import GreenRouteDomain

/// Persists `AppSettings` to `UserDefaults`.
///
/// Scalar values (e.g. `maxRouteDurationMinutes`) are stored directly. `SavedAddress`
/// values are JSON-encoded because `UserDefaults` cannot store arbitrary `Codable` types
/// natively.
///
/// Marked `@unchecked Sendable` because `UserDefaults` is thread-safe but not formally `Sendable`.
public final class UserDefaultsSettingsRepository: SettingsRepository, @unchecked Sendable {

    private let defaults: UserDefaults
    /// Namespace prefix for all GreenRoute settings keys, preventing collisions with other app settings.
    private let prefix = "gr_settings_"

    /// - Parameter defaults: The `UserDefaults` suite to use. Defaults to `.standard`.
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Loads settings from `UserDefaults`, falling back to `AppSettings.default` for any key
    /// that has not yet been written (e.g. on first launch).
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

    /// Writes all settings to `UserDefaults`.
    ///
    /// If JSON encoding of an address fails (which should never happen given `SavedAddress`
    /// is fully `Codable`), the key is removed to avoid leaving stale data behind.
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

    /// Builds a namespaced `UserDefaults` key from a bare field name.
    private func key(_ name: String) -> String {
        "\(prefix)\(name)"
    }
}
