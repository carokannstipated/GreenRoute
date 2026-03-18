//
//  RecurringPatternEntity.swift
//  GreenRouteData
//
//  Created by David Rivera on 17/03/2026.
//


import Foundation
import SwiftData

@Model
public final class RecurringPatternEntity {

    @Attribute(.unique) public var id: UUID
    public var kindRaw: String
    public var windowStartMinutes: Int
    public var windowEndMinutes: Int
    public var evidenceCount: Int
    public var confidence: Double

    public init(
        id: UUID,
        kindRaw: String,
        windowStartMinutes: Int,
        windowEndMinutes: Int,
        evidenceCount: Int,
        confidence: Double
    ) {
        self.id = id
        self.kindRaw = kindRaw
        self.windowStartMinutes = windowStartMinutes
        self.windowEndMinutes = windowEndMinutes
        self.evidenceCount = evidenceCount
        self.confidence = confidence
    }
}