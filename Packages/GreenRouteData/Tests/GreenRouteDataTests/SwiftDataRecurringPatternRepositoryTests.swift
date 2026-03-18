//
//  SwiftDataRecurringPatternRepositoryTests.swift
//  GreenRouteData
//
//  Created by David Rivera on 17/03/2026.
//


import XCTest
import SwiftData
@testable import GreenRouteData
@testable import GreenRouteDomain

final class SwiftDataRecurringPatternRepositoryTests: XCTestCase {

    private var container: ModelContainer!
    private var repository: SwiftDataRecurringPatternRepository!

    override func setUpWithError() throws {
        let schema = Schema([
            RecurringPatternEntity.self
        ])

        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        repository = SwiftDataRecurringPatternRepository(container: container)
    }

    override func tearDownWithError() throws {
        container = nil
        repository = nil
    }

    func test_saveAndFetchPattern() async throws {
        // Given
        let pattern = RecurringPattern(
            window: TimeWindow(startMinutes: 600, endMinutes: 660), // 10:00–11:00
            evidenceCount: 5,
            confidence: 0.8
        )

        // When
        try await repository.save(pattern)
        let fetched = try await repository.fetchAll()

        // Then
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.window.startMinutes, 600)
        XCTAssertEqual(fetched.first?.window.endMinutes, 660)
        XCTAssertEqual(fetched.first?.evidenceCount, 5)
        XCTAssertEqual(fetched.first?.confidence, 0.8)
    }
    

    func test_fetchEmpty_returnsNoPatterns() async throws {
           let fetched = try await repository.fetchAll()
           XCTAssertTrue(fetched.isEmpty, "Expected no patterns in an empty store.")
       }
    
       func test_saveMultiple_fetchAllReturnsAll() async throws {
           let p1 = RecurringPattern(
               window: TimeWindow(startMinutes: 480, endMinutes: 540),
               evidenceCount: 3,
               confidence: 0.6
           )
           let p2 = RecurringPattern(
               window: TimeWindow(startMinutes: 600, endMinutes: 660),
               evidenceCount: 5,
               confidence: 0.8
           )
           let p3 = RecurringPattern(
               window: TimeWindow(startMinutes: 720, endMinutes: 780),
               evidenceCount: 2,
               confidence: 0.5
           )
    
           try await repository.save(p1)
           try await repository.save(p2)
           try await repository.save(p3)
    
           let fetched = try await repository.fetchAll()
           XCTAssertEqual(fetched.count, 3)
    
           XCTAssertTrue(fetched.contains { $0.window.startMinutes == 480 && $0.window.endMinutes == 540 })
           XCTAssertTrue(fetched.contains { $0.window.startMinutes == 600 && $0.window.endMinutes == 660 })
           XCTAssertTrue(fetched.contains { $0.window.startMinutes == 720 && $0.window.endMinutes == 780 })
       }
    
       func test_updateExistingPattern_persistsChanges() async throws {
           let id = UUID()
           let original = RecurringPattern(
               id: id,
               window: TimeWindow(startMinutes: 600, endMinutes: 660),
               evidenceCount: 5,
               confidence: 0.8
           )
           try await repository.save(original)
    
           let updated = RecurringPattern(
               id: id,
               window: TimeWindow(startMinutes: 600, endMinutes: 660),
               evidenceCount: 7,
               confidence: 0.9
           )
           try await repository.save(updated)
    
           let fetched = try await repository.fetchAll()
           XCTAssertEqual(fetched.count, 1)
           XCTAssertEqual(fetched.first?.evidenceCount, 7)
           XCTAssertEqual(fetched.first?.confidence, 0.9)
       }
    

    func test_confidenceBounds_validValuesAreAccepted() throws {
        let low = RecurringPattern(
            window: TimeWindow(startMinutes: 600, endMinutes: 660),
            evidenceCount: 1,
            confidence: 0.0
        )
        let high = RecurringPattern(
            window: TimeWindow(startMinutes: 600, endMinutes: 660),
            evidenceCount: 1,
            confidence: 1.0
        )
        XCTAssertEqual(low.confidence, 0.0)
        XCTAssertEqual(high.confidence, 1.0)
    }
}

