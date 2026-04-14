//
//  AppSettings.swift
//  GreenRouteDomain
//

import Foundation

public struct AppSettings: Equatable, Sendable {
    public var maxRouteDurationMinutes: Int
    public var homeAddress: SavedAddress?
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

    public static let `default` = AppSettings()
}
