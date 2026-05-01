//
//  LocationStore.swift
//  GreenRoute
//
//  Created by Freja Egelund Grønnemose on 14/04/2026.
//
// In-memory store that holds the most recently known device coordinate.
// Shared between view models that need location without subscribing to the full service event stream.

import Foundation
import GreenRouteDomain

/// Lightweight observable container for the user's last known location.
/// Updated by GreenBreakViewModel whenever a significant location change event arrives from the service.
@Observable
final class LocationStore {
    /// The most recently received coordinate from a significant location change, or nil if none has arrived yet.
    var lastKnownCoordinate: Coordinate?
}
