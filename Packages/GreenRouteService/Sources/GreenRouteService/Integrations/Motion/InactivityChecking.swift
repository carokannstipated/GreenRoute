import Foundation
import GreenRouteDomain

public protocol InactivityChecking: Sendable {
    @discardableResult
    func checkInactivity() async -> InactivityEvent?
}
