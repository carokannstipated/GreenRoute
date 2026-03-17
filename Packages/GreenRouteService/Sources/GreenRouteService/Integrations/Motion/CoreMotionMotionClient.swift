//
//  CoreMotionMotionClient.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 03/03/2026.
//

import Foundation
import CoreMotion

final class CoreMotionMotionClient: MotionClient {

    private let manager = CMMotionActivityManager()
    private let queue: OperationQueue = {
        let q = OperationQueue()
        q.name = "GreenRouteService.CoreMotionMotionClient"
        q.qualityOfService = .utility
        return q
    }()

    func isActivityAvailable() -> Bool {
        CMMotionActivityManager.isActivityAvailable()
    }

    func startActivityUpdates(handler: @escaping (MotionActivity) -> Void) {
        guard isActivityAvailable() else { return }

        manager.startActivityUpdates(to: queue) { activity in
            guard let a = activity else { return }

            let mapped = MotionActivity(
                stationary: a.stationary,
                walking: a.walking,
                running: a.running,
                cycling: a.cycling,
                automotive: a.automotive
            )

            handler(mapped)
        }
    }

    func stopActivityUpdates() {
        manager.stopActivityUpdates()
    }
}
