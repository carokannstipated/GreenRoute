//
//  PatternDetector.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//
import Foundation

public struct PatternDetector: Sendable {
    
    public init() {}
    
    //Detects a daily recurring inactivity time window.
        //- Parameters:
        // - episodes: Inactivity episodes across multiple days
        // - toleranceMinutes: Allowed deviation around the central time
        // - minimumEvidence: Minimum number of days required
    
    public func detectDailyTimePattern(
        from episodes: [InactivityEvent],
        toleranceMinutes: Int = 30,
        minimumEvidence: Int = 3,
        calendar: Calendar
    ) -> RecurringPattern? {
        
        guard episodes.count >= minimumEvidence else { return nil }
                
        // Extract minutes-from-midnight for each episode start
        let minutes = episodes.map {
        calendar.component(.hour, from: $0.start) * 60 +
        calendar.component(.minute, from: $0.start)
        }
                
        // Use average time as central estimate
        let average = minutes.reduce(0, +) / minutes.count
                
        // Count how many fall within tolerance
        let matching = minutes.filter {
            abs($0 - average) <= toleranceMinutes
        }
                
        guard matching.count >= minimumEvidence else { return nil }
                
        let window = TimeWindow(
            startMinutes: max(0, average - toleranceMinutes),
            endMinutes: min(1440, average + toleranceMinutes)
        )
                
        let confidence = Double(matching.count) / Double(episodes.count)
                
        return RecurringPattern(
            window: window,
            evidenceCount: matching.count,
            confidence: confidence
        )
    }
}
