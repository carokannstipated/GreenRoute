// Test double for MotionClient that provides configurable stub activity arrays
// and lets tests push live updates into the monitor under test.

@testable import GreenRouteService
import Foundation

/// Simulates CMMotionActivityManager without touching the real CoreMotion framework.
/// `queryActivity` returns `stubbedActivities`; `push(_:)` delivers live updates to the handler.
final class FakeMotionClient: MotionClient, @unchecked Sendable {

    /// The handler registered via `startActivityUpdates`; nil when not monitoring.
    private var handler: ((MotionActivity) -> Void)?

    /// Activities returned by `queryActivity(from:to:)` regardless of the date range.
    var stubbedActivities: [MotionActivity] = []

    func isActivityAvailable() -> Bool { true }

    func startActivityUpdates(handler: @escaping (MotionActivity) -> Void) {
        self.handler = handler
    }

    func stopActivityUpdates() {
        handler = nil
    }

    /// Delivers a synthetic activity update to the registered handler.
    func push(_ activity: MotionActivity) {
        handler?(activity)
    }

    func queryActivity(from start: Date, to end: Date) async -> [MotionActivity] {
        stubbedActivities
    }
}
