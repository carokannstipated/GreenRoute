//
//  ServiceEvent.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 03/03/2026.
//

import Foundation
import GreenRouteDomain

public enum ServiceEvent: Sendable {
    case inactivityDetected(InactivityEvent)
    case locationVisit(LocationVisit)
    case significantLocationChange(latitude: Double, longitude: Double)
}
