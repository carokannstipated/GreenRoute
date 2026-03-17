//
//  RecurringPatternMapper.swift
//  GreenRouteData
//
//  Created by David Rivera on 17/03/2026.
//


import Foundation
import GreenRouteDomain

enum RecurringPatternMapper {

    static func toEntity(_ model: RecurringPattern) -> RecurringPatternEntity {
        RecurringPatternEntity(
            id: model.id,
            kindRaw: kindRaw(model.kind),
            windowStartMinutes: model.window.startMinutes,
            windowEndMinutes: model.window.endMinutes,
            evidenceCount: model.evidenceCount,
            confidence: model.confidence
        )
    }

    static func toDomain(_ entity: RecurringPatternEntity) -> RecurringPattern {
        RecurringPattern(
            id: entity.id,
            kind: kindFromRaw(entity.kindRaw),
            window: TimeWindow(
                startMinutes: entity.windowStartMinutes,
                endMinutes: entity.windowEndMinutes
            ),
            evidenceCount: entity.evidenceCount,
            confidence: entity.confidence
        )
    }

    private static func kindRaw(_ kind: RecurringPattern.Kind) -> String {
        switch kind {
        case .dailyTimeWindow: return "dailyTimeWindow"
        }
    }

    private static func kindFromRaw(_ raw: String) -> RecurringPattern.Kind {
        switch raw {
        case "dailyTimeWindow": return .dailyTimeWindow
        default: return .dailyTimeWindow
        }
    }
}