//
//  FakeMotionClient.swift
//  GreenRouteService
//
//  Created by Freja Egelund Grønnemose on 03/03/2026.
//

@testable import GreenRouteService

final class FakeMotionClient: MotionClient, @unchecked Sendable {

    private var handler: ((MotionActivity) -> Void)?
    var stubbedActivities: [MotionActivity] = []

    func isActivityAvailable() -> Bool { true }

    func startActivityUpdates(handler: @escaping (MotionActivity) -> Void) {
        self.handler = handler
    }

    func stopActivityUpdates() {
        handler = nil
    }

    func push(_ activity: MotionActivity) {
        handler?(activity)
    }

    func queryActivity(from start: Date, to end: Date) async -> [MotionActivity] {
        stubbedActivities
    }
}
