//
//  ModelContainerFactory.swift
//  GreenRouteData
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import SwiftData

public enum ModelContainerFactory {

    public static func makePersistentContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: GreenRouteSchema.schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: GreenRouteSchema.schema, configurations: configuration)
    }

    public static func makeInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: GreenRouteSchema.schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: GreenRouteSchema.schema, configurations: configuration)
    }
}
