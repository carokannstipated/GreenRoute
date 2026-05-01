// Periodically polls CoreMotion history to detect prolonged stationary periods
// and emits an InactivityEvent when the threshold is exceeded.

import Foundation
import GreenRouteDomain

/// Actor that runs a background polling loop, querying the `MotionClient` for activity history
/// within a rolling time window and emitting an `inactivityDetected` event when appropriate.
actor InactivityMonitor: InactivityChecking {

    /// Tuning parameters for the inactivity detection algorithm.
    struct Config: Sendable {
        /// How long (in seconds) the user must be continuously stationary before an event fires.
        let inactivityThreshold: TimeInterval

        /// How often to poll while the app is in the foreground.
        /// Capped at 60 s to avoid excessive wakeups, but never longer than the threshold itself.
        var foregroundCheckInterval: TimeInterval {
            min(inactivityThreshold, 60)
        }
    }

    private let motion: MotionClient
    private let clock: Clock
    private let config: Config
    /// Closure that forwards `ServiceEvent` values to the `DependencyContainer`.
    private let emit: @Sendable (ServiceEvent) -> Void

    /// Tracks the window end timestamp of the last emitted event to prevent re-firing
    /// before `inactivityThreshold` seconds have elapsed since the previous emission.
    private var lastEmittedWindowEnd: Date?

    /// The background polling task; non-nil while monitoring is active.
    private var monitoringTask: Task<Void, Never>?

    init(
        motion: MotionClient,
        clock: Clock,
        config: Config,
        emit: @escaping @Sendable (ServiceEvent) -> Void
    ) {
        self.motion = motion
        self.clock = clock
        self.config = config
        self.emit = emit
    }

    /// Starts the polling loop. The first check is delayed by `inactivityThreshold` so
    /// the monitor never fires immediately after launch. Subsequent calls before `stop()` are no-ops.
    func start() {
        guard monitoringTask == nil else { return }

        let initialDelay = config.inactivityThreshold
        let checkInterval = config.foregroundCheckInterval

        monitoringTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(initialDelay))

            while !Task.isCancelled {
                guard let self else { return }
                await self.checkInactivity()
                try? await Task.sleep(for: .seconds(checkInterval))
            }
        }
    }

    /// Cancels the polling loop and resets deduplication state so the next `start()` begins fresh.
    func stop() {
        monitoringTask?.cancel()
        monitoringTask = nil
        lastEmittedWindowEnd = nil
    }

    /// Queries the motion history for the most recent `inactivityThreshold`-sized window
    /// and delegates to `handleActivities(_:windowStart:windowEnd:)`.
    @discardableResult
    func checkInactivity() async -> InactivityEvent? {
        let now = clock.now()
        let windowStart = now.addingTimeInterval(-config.inactivityThreshold)
        let activities = await motion.queryActivity(from: windowStart, to: now)
        return handleActivities(activities, windowStart: windowStart, windowEnd: now)
    }

    /// Evaluates a batch of activity samples and emits an `inactivityDetected` event
    /// if all three conditions are met:
    /// 1. The sample array is non-empty (no data ≠ confirmed stationary).
    /// 2. Every sample in the window reports stationary with no movement flags.
    /// 3. At least `inactivityThreshold` seconds have passed since the last emission,
    ///    preventing duplicate events for the same sedentary period.
    @discardableResult
    func handleActivities(_ activities: [MotionActivity], windowStart: Date, windowEnd: Date) -> InactivityEvent? {
        guard !activities.isEmpty else { return nil }

        guard activities.allSatisfy(\.isStationary) else { return nil }

        if let last = lastEmittedWindowEnd {
            guard windowEnd.timeIntervalSince(last) >= config.inactivityThreshold else { return nil }
        }

        let event = InactivityEvent(start: windowStart, end: windowEnd)
        emit(.inactivityDetected(event))
        lastEmittedWindowEnd = windowEnd
        return event
    }
}
