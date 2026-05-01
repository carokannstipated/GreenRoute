// Factory for creating configured ModelContainer instances for production and testing.

import SwiftData
import Foundation

/// Creates `ModelContainer` instances for the full GreenRoute schema.
///
/// Use `makePersistentContainer()` in the production app and `makeInMemoryContainer()`
/// in unit tests or SwiftUI previews to avoid touching the on-disk store.
public enum ModelContainerFactory {

    /// Creates a container backed by a file at `Application Support/default.store`.
    ///
    /// The Application Support directory is created automatically if it does not exist.
    /// Placing the store in Application Support (rather than Documents) ensures it is
    /// excluded from iCloud backup by default.
    public static func makePersistentContainer() throws -> ModelContainer {
        let appSupportURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let storeURL = appSupportURL.appendingPathComponent("default.store")

        let configuration = ModelConfiguration(
            schema: GreenRouteSchema.schema,
            url: storeURL,
            allowsSave: true
        )

        return try ModelContainer(for: GreenRouteSchema.schema, configurations: configuration)
    }

    /// Creates a container that stores data in memory only.
    ///
    /// Data is discarded when the container is deallocated.
    /// Suitable for unit tests and SwiftUI previews.
    public static func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: GreenRouteSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: GreenRouteSchema.schema, configurations: configuration)
    }
}
