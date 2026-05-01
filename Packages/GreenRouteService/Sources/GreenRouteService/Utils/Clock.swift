// Defines the Clock protocol and SystemClock, allowing deterministic time
// injection in tests without mocking Foundation.Date directly.

import Foundation

/// Abstracts the system clock so monitors can be tested with a controlled, fixed time value.
protocol Clock {
    /// Returns the current point in time.
    func now() -> Date
}

/// Production implementation that delegates directly to `Date()`.
struct SystemClock: Clock {
    func now() -> Date { Date() }
}
