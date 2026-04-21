//
//  LocationStore.swift
//  GreenRoute
//
//  Created by Freja Egelund Grønnemose on 14/04/2026.
//


import Foundation
import GreenRouteDomain

@Observable
final class LocationStore {
    var lastKnownCoordinate: Coordinate?
}