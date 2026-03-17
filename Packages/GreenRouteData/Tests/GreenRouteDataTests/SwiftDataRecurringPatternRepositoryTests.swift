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

    func test_saveAndFetchPattern() throws {
        // Given
        let pattern = RecurringPattern(
            window: TimeWindow(startMinutes: 600, endMinutes: 660), // 10:00–11:00
            evidenceCount: 5,
            confidence: 0.8
        )

        // When
        try repository.save(pattern)
        let fetched = try repository.fetchAll()

        // Then
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.window.startMinutes, 600)
        XCTAssertEqual(fetched.first?.window.endMinutes, 660)
        XCTAssertEqual(fetched.first?.evidenceCount, 5)
        XCTAssertEqual(fetched.first?.confidence, 0.8)
    }
    
/*
    func test_fetchEmpty_returnsNoPatterns() throws {
        let fetched = try repository.fetchAll()
        XCTAssertTrue(fetched.isEmpty, "Expected no patterns in an empty store.")
    }

    func test_saveMultiple_fetchAllReturnsAll() throws {
        let p1 = RecurringPattern(
            window: TimeWindow(startMinutes: 480, endMinutes: 540), // 08:00–09:00
            evidenceCount: 3,
            confidence: 0.6
        )
        let p2 = RecurringPattern(
            window: TimeWindow(startMinutes: 600, endMinutes: 660), // 10:00–11:00
            evidenceCount: 5,
            confidence: 0.8
        )
        let p3 = RecurringPattern(
            window: TimeWindow(startMinutes: 720, endMinutes: 780), // 12:00–13:00
            evidenceCount: 2,
            confidence: 0.5
        )

        try repository.save(p1)
        try repository.save(p2)
        try repository.save(p3)

        let fetched = try repository.fetchAll()
        XCTAssertEqual(fetched.count, 3)

        // Optionally assert values are present (order-agnostic)
        let windows = Set(fetched.map { ($0.window.startMinutes, $0.window.endMinutes) })
        XCTAssertTrue(windows.contains((480, 540)))
        XCTAssertTrue(windows.contains((600, 660)))
        XCTAssertTrue(windows.contains((720, 780)))
    }

    func test_updateExistingPattern_persistsChanges() throws {
        // This assumes your repository interprets "save" as upsert, or you have a dedicated update method.
        // If identity is based on the time window, adapt accordingly to how your repository identifies records.
        var pattern = RecurringPattern(
            window: TimeWindow(startMinutes: 600, endMinutes: 660),
            evidenceCount: 5,
            confidence: 0.8
        )
        try repository.save(pattern)

        // Update fields
        pattern.evidenceCount = 7
        pattern.confidence = 0.9
        try repository.save(pattern)

        let fetched = try repository.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.evidenceCount, 7)
        XCTAssertEqual(fetched.first?.confidence, 0.9)
    }

    func test_deletePattern_removesOnlyThatPattern() throws {
        // Only include this if your repository exposes a delete API.
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
        try repository.save(p1)
        try repository.save(p2)

        // Assuming delete takes a RecurringPattern or some identifier
        try repository.delete(p1)

        let fetched = try repository.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.window.startMinutes, 600)
        XCTAssertEqual(fetched.first?.window.endMinutes, 660)
    }

    func test_invalidWindow_throwsOrIsRejected() throws {
        // If your domain enforces start < end, this should either throw or be rejected.
        // Adjust expectations to your actual validation behavior (throw, ignore, clamp).
        let invalid = RecurringPattern(
            window: TimeWindow(startMinutes: 700, endMinutes: 660), // start >= end
            evidenceCount: 1,
            confidence: 0.5
        )

        do {
            try repository.save(invalid)
            // If save doesn't throw, ensure it didn't persist
            let fetched = try repository.fetchAll()
            XCTAssertTrue(fetched.isEmpty, "Invalid pattern should not be persisted.")
        } catch {
            // If you expect a specific error type, assert it here
            // e.g., XCTAssertTrue(error is RepositoryError.invalidWindow)
        }
    }
*/
    func test_confidenceBounds_clampedOrRejected() throws {
        // If confidence must be in [0,1], check behavior for out-of-range values.
        let over = RecurringPattern(
            window: TimeWindow(startMinutes: 600, endMinutes: 660),
            evidenceCount: 1,
            confidence: 1.5
        )
        let under = RecurringPattern(
            window: TimeWindow(startMinutes: 600, endMinutes: 660),
            evidenceCount: 1,
            confidence: -0.2
        )

        // Depending on your domain rules: reject or clamp
        do {
            try repository.save(over)
            try repository.save(under)
            let fetched = try repository.fetchAll()
            // If clamping, verify clamped values
            for item in fetched {
                XCTAssertGreaterThanOrEqual(item.confidence, 0.0)
                XCTAssertLessThanOrEqual(item.confidence, 1.0)
            }
        } catch {
            // If rejection is expected, you can assert errors here instead
        }
    }
}

