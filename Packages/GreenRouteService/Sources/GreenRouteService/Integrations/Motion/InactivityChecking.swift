import Foundation

public protocol InactivityChecking: Sendable {
    func checkInactivity() async
}
