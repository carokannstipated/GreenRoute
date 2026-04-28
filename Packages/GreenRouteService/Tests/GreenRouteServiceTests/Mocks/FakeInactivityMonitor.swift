//
//  FakeInactivityMonitor.swift
//  GreenRouteService
//

@testable import GreenRouteService

actor FakeInactivityMonitor: InactivityChecking {
    private(set) var checkInactivityCallCount = 0

    func checkInactivity() async {
        checkInactivityCallCount += 1
    }
}
