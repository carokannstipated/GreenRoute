//
//  SavedAddress.swift
//  GreenRouteDomain
//

import Foundation

public struct SavedAddress: Equatable, Hashable, Sendable {
    public let displayName: String
    public let coordinate: Coordinate

    public init(displayName: String, coordinate: Coordinate) {
        precondition(
            !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            "SavedAddress displayName must not be empty"
        )
        self.displayName = displayName
        self.coordinate = coordinate
    }
}
