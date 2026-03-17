//
//  InactivityMonitor.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 03/03/2026.
//

import Foundation
import CoreMotion
import GreenRouteDomain

import Foundation
import GreenRouteDomain

actor InactivityMonitor {

    struct Config: Sendable {
        let inactivityThreshold: TimeInterval
    }

    private enum State {
        case active
        case maybeInactive(since: Date)
        case inactive(since: Date)
    }

    private let motion: MotionClient
    private let clock: Clock
    private let config: Config
    private let emit: @Sendable (ServiceEvent) -> Void

    private var state: State = .active

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
        motion.startActivityUpdates { [weak self] activity in
            guard let self else { return }
            Task {
                await self.handle(activity)
            }
        }
    }

    func stop() {
        motion.stopActivityUpdates()
        state = .active
    }

    private func handle(_ activity: MotionActivity) {
        let now = clock.now()

        if activity.isMoving {
            state = .active
            return
        }

        guard activity.isStationary else { return }

        switch state {
        case .active:
            state = .maybeInactive(since: now)

        case .maybeInactive(let since):
            guard now.timeIntervalSince(since) >= config.inactivityThreshold else { return }
            let event = InactivityEvent(start: since, end: now) // tilpas hvis jeres model er anderledes
            emit(.inactivityDetected(event))
            state = .inactive(since: since)

        case .inactive:
            break
        }
    }
}
