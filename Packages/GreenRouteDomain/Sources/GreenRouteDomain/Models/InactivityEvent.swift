//
//  InactivityEvent.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import Foundation

public struct InactivityEvent: Equatable, Hashable, Sendable, Identifiable {
    
    public let id: UUID
    public let start: Date
    public let end: Date
    
    public init(id: UUID = UUID(), start: Date, end: Date) {
        precondition(end >= start, "End date must not be earlier than start date")
        
        self.id = id
        self.start = start
        self.end = end
    }
    
    // Duration of inactivity in seconds
    public var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
}
