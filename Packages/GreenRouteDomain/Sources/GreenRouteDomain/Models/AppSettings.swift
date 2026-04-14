//
//  AppSettings.swift
//  GreenRouteDomain
//

import Foundation

public struct AppSettings: Equatable, Sendable {
    public var maxRouteDurationMinutes: Int

    // Add new settings here as needed

    public init(maxRouteDurationMinutes: Int = 15) {
        self.maxRouteDurationMinutes = maxRouteDurationMinutes
    }

    public static let `default` = AppSettings()
}
