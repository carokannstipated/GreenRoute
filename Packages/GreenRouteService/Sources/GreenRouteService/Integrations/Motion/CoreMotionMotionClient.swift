//
//  CoreMotionMotionClient.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 03/03/2026.
//

import Foundation
import CoreMotion

#if os(iOS)
final class CoreMotionMotionClient: MotionClient, @unchecked Sendable {

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

    func queryActivity(from start: Date, to end: Date) async -> [MotionActivity] {
        guard isActivityAvailable() else { return [] }
        return await withCheckedContinuation { continuation in
            manager.queryActivityStarting(from: start, to: end, to: queue) { activities, error in
                let mapped = (error == nil ? activities : nil)?.map { a in
                    MotionActivity(
                        stationary: a.stationary,
                        walking: a.walking,
                        running: a.running,
                        cycling: a.cycling,
                        automotive: a.automotive
                    )
                } ?? []
                continuation.resume(returning: mapped)
            }
        }
    }
}
#else
final class CoreMotionMotionClient: MotionClient, @unchecked Sendable {
    func isActivityAvailable() -> Bool { false }
    func startActivityUpdates(handler: @escaping (MotionActivity) -> Void) {}
    func stopActivityUpdates() {}
    func queryActivity(from start: Date, to end: Date) async -> [MotionActivity] { [] }
}
#endif
