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

        var foregroundCheckInterval: TimeInterval {
            min(inactivityThreshold, 60)
        }
    }

    private let motion: MotionClient
    private let clock: Clock
    private let config: Config
    private let emit: @Sendable (ServiceEvent) -> Void

    private var lastEmittedWindowEnd: Date?
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

    func stop() {
        monitoringTask?.cancel()
        monitoringTask = nil
        lastEmittedWindowEnd = nil
    }

    @discardableResult
    func checkInactivity() async -> InactivityEvent? {
        let now = clock.now()
        let windowStart = now.addingTimeInterval(-config.inactivityThreshold)
        let activities = await motion.queryActivity(from: windowStart, to: now)
        return handleActivities(activities, windowStart: windowStart, windowEnd: now)
    }

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
