//
//  ModelContainerFactory.swift
//  GreenRouteData
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import SwiftData
import Foundation

public enum ModelContainerFactory {

    public static func makePersistentContainer() throws -> ModelContainer {
        // Get the Application Support directory and ensure it exists
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

    public static func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: GreenRouteSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: GreenRouteSchema.schema, configurations: configuration)
    }
}
