//
//  SwiftDataInactivityEventRepositoryTests.swift
//  GreenRouteData
//
//  Created by David Rivera on 18/03/2026.
//


import XCTest
import SwiftData
@testable import GreenRouteData
@testable import GreenRouteDomain
 
final class SwiftDataInactivityEventRepositoryTests: XCTestCase {
 
    private var container: ModelContainer!
    private var repository: SwiftDataInactivityEventRepository!
 
    override func setUpWithError() throws {
        let schema = Schema([
            InactivityEventEntity.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        repository = SwiftDataInactivityEventRepository(container: container)
    }
 
    override func tearDownWithError() throws {
        container = nil
        repository = nil
    }
 
    func test_fetchEmpty_returnsNoEvents() async throws {
        let now = Date()
        let fetched = try await repository.fetch(from: now.addingTimeInterval(-3600), to: now)
        XCTAssertTrue(fetched.isEmpty, "Expected no events in an empty store.")
    }
 
    func test_saveAndFetch_returnsEvent() async throws {
        let now = Date()
        let event = InactivityEvent(
            start: now.addingTimeInterval(-1800),
            end: now
        )
 
        try await repository.save(event)
        let fetched = try await repository.fetch(
            from: now.addingTimeInterval(-3600),
            to: now.addingTimeInterval(1)
        )
 
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, event.id)
        XCTAssertEqual(fetched.first?.start, event.start)
        XCTAssertEqual(fetched.first?.end, event.end)
    }
 
    func test_saveMultiple_fetchAllReturnsAll() async throws {
        let now = Date()
        let e1 = InactivityEvent(
            start: now.addingTimeInterval(-3600),
            end: now.addingTimeInterval(-2700)
        )
        let e2 = InactivityEvent(
            start: now.addingTimeInterval(-2700),
            end: now.addingTimeInterval(-1800)
        )
        let e3 = InactivityEvent(
            start: now.addingTimeInterval(-1800),
            end: now.addingTimeInterval(-900)
        )
 
        try await repository.save(e1)
        try await repository.save(e2)
        try await repository.save(e3)
 
        let fetched = try await repository.fetch(
            from: now.addingTimeInterval(-7200),
            to: now
        )
 
        XCTAssertEqual(fetched.count, 3)
        let ids = Set(fetched.map { $0.id })
        XCTAssertTrue(ids.contains(e1.id))
        XCTAssertTrue(ids.contains(e2.id))
        XCTAssertTrue(ids.contains(e3.id))
    }
 
    func test_fetch_excludesEventsOutsideRange() async throws {
        let now = Date()
        let inside = InactivityEvent(
            start: now.addingTimeInterval(-1800),
            end: now.addingTimeInterval(-900)
        )
        let outside = InactivityEvent(
            start: now.addingTimeInterval(-7200),
            end: now.addingTimeInterval(-5400)
        )
 
        try await repository.save(inside)
        try await repository.save(outside)
 
        let fetched = try await repository.fetch(
            from: now.addingTimeInterval(-3600),
            to: now
        )
 
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, inside.id)
    }
 
    func test_fetch_resultsAreSortedByStartDescending() async throws {
        let now = Date()
        let early = InactivityEvent(
            start: now.addingTimeInterval(-3600),
            end: now.addingTimeInterval(-2700)
        )
        let late = InactivityEvent(
            start: now.addingTimeInterval(-1800),
            end: now.addingTimeInterval(-900)
        )
 
        try await repository.save(early)
        try await repository.save(late)
 
        let fetched = try await repository.fetch(
            from: now.addingTimeInterval(-7200),
            to: now
        )
 
        XCTAssertEqual(fetched.first?.id, late.id)
        XCTAssertEqual(fetched.last?.id, early.id)
    }
}