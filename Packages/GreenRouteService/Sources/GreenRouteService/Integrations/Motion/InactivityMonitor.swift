//
//  InactivityMonitor.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 03/03/2026.
//

import Foundation
import GreenRouteDomain

actor InactivityMonitor: InactivityChecking {

    struct Config: Sendable {
        let inactivityThreshold: TimeInterval
    }

    private static let lookbackInterval: TimeInterval = 20 * 60

    private let motion: MotionClient
    private let clock: Clock
    private let config: Config
    private let emit: @Sendable (ServiceEvent) -> Void

    private var lastEmittedWindowEnd: Date?

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

    func start() {}

    func stop() {
        lastEmittedWindowEnd = nil
    }

    func checkInactivity() async {
        let now = clock.now()
        let windowStart = now.addingTimeInterval(-Self.lookbackInterval)
        let activities = await motion.queryActivity(from: windowStart, to: now)
        handleActivities(activities, windowStart: windowStart, windowEnd: now)
    }

    func handleActivities(_ activities: [MotionActivity], windowStart: Date, windowEnd: Date) {
        guard !activities.isEmpty else { return }

        guard activities.allSatisfy(\.isStationary) else { return }

        if let last = lastEmittedWindowEnd {
            guard windowEnd.timeIntervalSince(last) >= config.inactivityThreshold else { return }
        }

        let event = InactivityEvent(start: windowStart, end: windowEnd)
        emit(.inactivityDetected(event))
        lastEmittedWindowEnd = windowEnd
    }
}
