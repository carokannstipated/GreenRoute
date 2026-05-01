// Defines the InactivityChecking protocol used to expose on-demand inactivity
// checking to the service facade without exposing the full InactivityMonitor API.

import Foundation
import GreenRouteDomain

/// Exposes a single on-demand inactivity check, decoupled from the full monitor lifecycle.
/// Conformers inspect recent motion history and return an `InactivityEvent` if the user
/// has been stationary for the configured threshold.
public protocol InactivityChecking: Sendable {
    /// Queries recent motion history and returns an `InactivityEvent` if the user has been
    /// continuously stationary for the threshold period, or nil otherwise.
    @discardableResult
    func checkInactivity() async -> InactivityEvent?
}
