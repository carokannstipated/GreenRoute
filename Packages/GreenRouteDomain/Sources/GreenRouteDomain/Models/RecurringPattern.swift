//
//  RecurringPattern.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import Foundation

public struct RecurringPattern: Equatable, Hashable, Sendable, Identifiable {
    
    public enum Kind: Equatable, Hashable, Sendable {
        case dailyTimeWindow
    }
    
    public let id: UUID
    public let kind: Kind
    
    // Start and end minutes from midnight in local time (0...1439).
    public let window: TimeWindow
    
    // How manu observation supports this pattern
    public let evidenceCount: Int
    
    // Confidence score 0...1 (rule-based heuristic is fine)
    public let confidence: Double
    
    public init(id: UUID = UUID(), kind: Kind = .dailyTimeWindow, window: TimeWindow, evidenceCount: Int, confidence: Double) {
        precondition(evidenceCount >= 0, "evidenceCount cannot be negative")
        precondition((0.0...1.0).contains(confidence), "confidence must be between 0 and 1")
        self.id = id
        self.kind = kind
        self.window = window
        self.evidenceCount = evidenceCount
        self.confidence = confidence
    }
}

// A daily time window expressed as minutes from midnight
public struct TimeWindow: Equatable, Hashable, Sendable {
    public let startMinutes: Int // 0...1439
    public let endMinutes: Int //0...1440 (end can be 1440 to represent end-of-day)
    
    public init(startMinutes: Int, endMinutes: Int){
        precondition((0...1439).contains(startMinutes), "startMinutes must be 0...1439")
        precondition((0...1440).contains(endMinutes), "endMinutes must be 0...1440")
        precondition(endMinutes > startMinutes, "endMinutes must be greater than startMinutes")
        
        self.startMinutes = startMinutes
        self.endMinutes = endMinutes
    }
    
    public func contains(minutesFromMidnight: Int) -> Bool {
        guard (0...1439).contains(minutesFromMidnight) else {return false }
        return minutesFromMidnight >= startMinutes && minutesFromMidnight < endMinutes
    }
}
