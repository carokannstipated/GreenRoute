//
//  RecordInactivityUseCaseTest.swift
//  GreenRouteDomain
//
//  Created by Freja Egelund Grønnemose on 28/02/2026.
//

import XCTest
@testable import GreenRouteDomain

final class RecordInactivityEventUseCaseTests: XCTestCase {

    func test_execute_savesEvent() async throws {
        let repo = FakeInactivityEventRepository()
        let useCase = RecordInactivityEventUseCase(repository: repo)

        let event = InactivityEvent(
            start: iso("2026-02-01T12:00:00Z"),
            end: iso("2026-02-01T12:30:00Z")
        )

        try await useCase.execute(event)

        let saved = await repo.allSaved()
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first, event)
    }
}

// MARK: - Fake

private actor FakeInactivityEventRepository: InactivityEventRepository {
    private var saved: [InactivityEvent] = []

    func save(_ event: InactivityEvent) async throws {
        saved.append(event)
    }

    func fetch(from start: Date, to end: Date) async throws -> [InactivityEvent] {
        saved.filter { $0.start >= start && $0.start < end }
    }

    func allSaved() -> [InactivityEvent] { saved }
}

// MARK: - Helper

private func iso(_ value: String) -> Date {
    ISO8601DateFormatter().date(from: value)!
}
