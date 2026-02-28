//
//  GreenArea.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import Foundation

public struct GreenArea: Equatable, Hashable, Sendable, Identifiable {
    
    public enum Kind: Equatable, Hashable, Sendable {
        case park
        case forest
        case natureReserve
        case beach
        case other
    }
    
    public let id: String
    public let name: String
    public let coordinate: Coordinate
    public let kind: Kind
    
    public init(id: String, name: String, coordinate: Coordinate, kind: Kind = .other) {
        precondition(!id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "GreenArea id must not be empty")
        precondition(!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "GreenArea name must not be empty")
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.kind = kind
    }
}
