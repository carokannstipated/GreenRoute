// Defines the MotionClient protocol and the MotionActivity value type that
// decouple CoreMotion from the InactivityMonitor actor.

import Foundation

/// A value-semantic snapshot of a single `CMMotionActivity` update.
/// Each flag mirrors the corresponding `CMMotionActivity` property.
struct MotionActivity: Sendable, Equatable {
    var stationary: Bool
    var walking: Bool
    var running: Bool
    var cycling: Bool
    var automotive: Bool

    /// True when any active transport mode is detected.
    var isMoving: Bool { walking || running || cycling || automotive }

    /// True only when stationary is reported and no active transport mode is detected.
    var isStationary: Bool { stationary && !isMoving }

    /// Preset used in tests to represent a fully stationary activity with no movement flags.
    static let stationaryOnly = MotionActivity(
        stationary: true, walking: false, running: false, cycling: false, automotive: false
    )

    /// Preset used in tests to represent a walking activity with no stationary flag.
    static let walking = MotionActivity(
        stationary: false, walking: true, running: false, cycling: false, automotive: false
    )
}

/// Abstracts `CMMotionActivityManager` to allow injection of test doubles into `InactivityMonitor`.
protocol MotionClient: Sendable {
    /// Returns true if motion activity data is available on this device.
    func isActivityAvailable() -> Bool
    /// Begins streaming live activity updates; `handler` is called on an internal queue.
    func startActivityUpdates(handler: @escaping (MotionActivity) -> Void)
    /// Stops live activity updates.
    func stopActivityUpdates()
    /// Returns the recorded activity samples for the given time window; empty on error or unavailability.
    func queryActivity(from start: Date, to end: Date) async -> [MotionActivity]
}
