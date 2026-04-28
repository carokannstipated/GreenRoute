//
//  MotionClient.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 03/03/2026.
//

import Foundation

struct MotionActivity: Sendable, Equatable {
    var stationary: Bool
    var walking: Bool
    var running: Bool
    var cycling: Bool
    var automotive: Bool

    var isMoving: Bool { walking || running || cycling || automotive }
    var isStationary: Bool { stationary && !isMoving }

    static let stationaryOnly = MotionActivity(
        stationary: true, walking: false, running: false, cycling: false, automotive: false
    )

    static let walking = MotionActivity(
        stationary: false, walking: true, running: false, cycling: false, automotive: false
    )
}

protocol MotionClient: Sendable {
    func isActivityAvailable() -> Bool
    func startActivityUpdates(handler: @escaping (MotionActivity) -> Void)
    func stopActivityUpdates()
    func queryActivity(from start: Date, to end: Date) async -> [MotionActivity]
}
