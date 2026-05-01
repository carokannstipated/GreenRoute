// Records the user's response to a single recommendation.

import Foundation

/// Captures the outcome of showing a `Recommendation` to the user.
///
/// Decisions are stored separately from recommendations so that a single recommendation
/// can accumulate multiple decisions over time (e.g. if it is shown again after being ignored).
public struct RecommendationDecision: Equatable, Hashable, Sendable, Identifiable {

    /// The three possible outcomes when a recommendation is presented to the user.
    public enum Decision: Equatable, Hashable, Sendable {
        /// The user tapped the notification or confirmed they will go for a walk.
        case accepted
        /// The user actively dismissed the recommendation.
        case dismissed
        /// The notification was delivered but the user took no action; recorded after a timeout.
        case ignored
    }

    public let id: UUID

    /// The `Recommendation.id` this decision belongs to.
    public let recommendationID: UUID

    /// What the user did with the recommendation.
    public let decision: Decision

    /// When the decision was recorded.
    public let timestamp: Date

    public init(id: UUID = UUID(), recommendationID: UUID, decision: Decision, timestamp: Date) {
        self.id = id
        self.recommendationID = recommendationID
        self.decision = decision
        self.timestamp = timestamp
    }
}
