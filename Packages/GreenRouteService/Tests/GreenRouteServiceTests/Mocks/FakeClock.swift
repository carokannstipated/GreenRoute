// Test double for the Clock protocol that returns a fixed, controllable date.

import Foundation
@testable import GreenRouteService

/// Returns a caller-specified `Date` on every `now()` call.
/// Allows tests to set the clock to any point in time without waiting for real time to pass.
final class FakeClock: Clock, @unchecked Sendable {
    /// The date returned by `now()`; can be mutated between calls to simulate time advancing.
    var current: Date
    init(current: Date) { self.current = current }
    func now() -> Date { current }
}
