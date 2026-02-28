//
//  TimeProviding.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import Foundation

public protocol TimeProviding: Sendable {
    var now: Date { get }
}
