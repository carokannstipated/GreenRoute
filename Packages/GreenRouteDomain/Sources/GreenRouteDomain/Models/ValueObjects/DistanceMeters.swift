//
//  DistanceMeters.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import Foundation

public struct DistanceMeters: Equatable, Hashable, Sendable {
    
    public let value: Double
    
    public init(value: Double) {
        precondition(value >= 0, "Distance cannot be negative")
        self.value = value
    }
}

extension DistanceMeters: Comparable {
    public static func < (lhs: DistanceMeters, rhs: DistanceMeters) -> Bool {
        lhs.value < rhs.value
    }
}
