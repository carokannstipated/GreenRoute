// Abstraction over the system clock, enabling deterministic time-based testing.

import Foundation

/// Provides the current point in time.
///
/// Inject a fixed implementation in tests rather than calling `Date()` directly,
/// so that time-sensitive logic can be exercised at any simulated timestamp.
public protocol TimeProviding: Sendable {
    var now: Date { get }
}
