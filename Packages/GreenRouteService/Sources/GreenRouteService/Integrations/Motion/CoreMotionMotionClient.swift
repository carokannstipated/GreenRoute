// Production CMMotionActivityManager adapter. Provides a platform-conditional implementation:
// the iOS build uses real CoreMotion data; the macOS/other build returns stubs.

import Foundation
import CoreMotion

#if os(iOS)
/// Live `MotionClient` implementation backed by `CMMotionActivityManager`.
/// Marked `@unchecked Sendable` because `CMMotionActivityManager` is not itself `Sendable`,
/// but all mutable access is serialised through the dedicated operation queue.
final class CoreMotionMotionClient: MotionClient, @unchecked Sendable {

    private let manager = CMMotionActivityManager()

    /// Dedicated queue used for all CoreMotion callbacks to avoid blocking the main thread.
    private let queue: OperationQueue = {
        let q = OperationQueue()
        q.name = "GreenRouteService.CoreMotionMotionClient"
        q.qualityOfService = .utility
        return q
    }()

    func isActivityAvailable() -> Bool {
        CMMotionActivityManager.isActivityAvailable()
    }

    /// Begins streaming activity updates. Silently exits if the hardware is unavailable.
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

    /// Queries historical activity data for the given window.
    /// Returns an empty array if the hardware is unavailable or the query returns an error.
    func queryActivity(from start: Date, to end: Date) async -> [MotionActivity] {
        guard isActivityAvailable() else { return [] }
        return await withCheckedContinuation { continuation in
            manager.queryActivityStarting(from: start, to: end, to: queue) { activities, error in
                // Treat any error as "no data" — the caller (InactivityMonitor) interprets
                // an empty result as insufficient evidence for inactivity.
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
/// Stub implementation for non-iOS targets where CoreMotion activity detection is unavailable.
final class CoreMotionMotionClient: MotionClient, @unchecked Sendable {
    func isActivityAvailable() -> Bool { false }
    func startActivityUpdates(handler: @escaping (MotionActivity) -> Void) {}
    func stopActivityUpdates() {}
    func queryActivity(from start: Date, to end: Date) async -> [MotionActivity] { [] }
}
#endif
