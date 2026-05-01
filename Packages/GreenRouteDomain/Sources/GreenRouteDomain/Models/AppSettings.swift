// User-configurable application preferences.

import Foundation

/// All user-facing settings for GreenRoute.
///
/// Loaded and saved by `SettingsRepository`. The `default` singleton represents
/// the out-of-the-box configuration before the user makes any changes.
public struct AppSettings: Equatable, Sendable {

    /// Maximum walking duration, in minutes, that a green-break recommendation may suggest.
    /// Acts as an upper bound on `Recommendation.estimatedWalkMinutes`.
    public var maxRouteDurationMinutes: Int

    /// The user's home address, used to classify `LocationVisit`s as `.home`.
    /// `nil` until the user configures it.
    public var homeAddress: SavedAddress?

    /// The user's work or study address, used to classify `LocationVisit`s as `.workOrStudy`.
    /// `nil` until the user configures it.
    public var workAddress: SavedAddress?

    public init(
        maxRouteDurationMinutes: Int = 15,
        homeAddress: SavedAddress? = nil,
        workAddress: SavedAddress? = nil
    ) {
        self.maxRouteDurationMinutes = maxRouteDurationMinutes
        self.homeAddress = homeAddress
        self.workAddress = workAddress
    }

    /// The factory-default settings, used as a baseline when no persisted settings exist.
    public static let `default` = AppSettings()
}
