// Test double for InactivityChecking that records call count without performing
// any real motion queries.

@testable import GreenRouteService
import GreenRouteDomain

/// Always returns nil from `checkInactivity()` and counts how many times it was called.
/// Useful for verifying that the service facade delegates inactivity checks correctly.
actor FakeInactivityMonitor: InactivityChecking {
    /// Number of times `checkInactivity()` has been invoked.
    private(set) var checkInactivityCallCount = 0

    func checkInactivity() async -> InactivityEvent? {
        checkInactivityCallCount += 1
        return nil
    }
}
