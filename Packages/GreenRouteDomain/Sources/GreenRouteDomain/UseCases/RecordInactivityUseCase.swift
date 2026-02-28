//
//  RecordInactivityUseCase.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import Foundation

public struct RecordInactivityEventUseCase: Sendable {

    private let repository: InactivityEventRepository

    public init(repository: InactivityEventRepository) {
        self.repository = repository
    }

    public func execute(_ event: InactivityEvent) async throws {
        try await repository.save(event)
    }
}
