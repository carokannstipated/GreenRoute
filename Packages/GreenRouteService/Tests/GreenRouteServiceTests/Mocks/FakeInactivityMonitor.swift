//
//  FakeInactivityMonitor.swift
//  GreenRouteService
//

@testable import GreenRouteService
import GreenRouteDomain

actor FakeInactivityMonitor: InactivityChecking {
    private(set) var checkInactivityCallCount = 0

    func checkInactivity() async -> InactivityEvent? {
        checkInactivityCallCount += 1
        return nil
    }
}
