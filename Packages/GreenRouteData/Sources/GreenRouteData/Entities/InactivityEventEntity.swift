//
//  InactivityEventEntity.swift
//  GreenRouteData
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import Foundation
import SwiftData

@Model
public final class InactivityEventEntity {
    @Attribute(.unique) public var id: UUID
    public var start: Date
    public var end: Date

    public init(id: UUID, start: Date, end: Date) {
        self.id = id
        self.start = start
        self.end = end
    }
}
