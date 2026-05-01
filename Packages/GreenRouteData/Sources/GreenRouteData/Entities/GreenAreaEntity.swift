// SwiftData entity for persisting a GreenArea domain model.

import Foundation
import SwiftData

/// Persistent storage representation of a `GreenArea`.
///
/// The `GreenArea.Kind` enum is stored as a raw `String` because SwiftData does not
/// natively support custom Swift enums. `GreenAreaMapper` handles the conversion.
@Model
public final class GreenAreaEntity {

    /// Unique identifier matching `GreenArea.id`. The `.unique` attribute enforces upsert semantics.
    @Attribute(.unique) public var id: String
    public var name: String
    /// Latitude component of the area's coordinate, stored flat to avoid nested-type limitations.
    public var latitude: Double
    public var longitude: Double
    /// Raw string representation of `GreenArea.Kind` (e.g. "park", "forest").
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
