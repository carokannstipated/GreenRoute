//
//  GreenAreaEntity.swift
//  GreenRouteData
//
//  Created by David Rivera on 17/03/2026.
//

import Foundation
import SwiftData

@Model
public final class GreenAreaEntity {

    @Attribute(.unique) public var id: String
    public var name: String
    public var latitude: Double
    public var longitude: Double
    public var kindRaw: String

    public init(
        id: String,
        name: String,
        latitude: Double,
        longitude: Double,
        kindRaw: String
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.kindRaw = kindRaw
    }
}
