//
//  UserDefaultsSettingsRepositoryTests.swift
//  GreenRouteTests
//

import XCTest
import GreenRouteDomain
@testable import GreenRouteData

final class UserDefaultsSettingsRepositoryTests: XCTestCase {

    private var sut: UserDefaultsSettingsRepository!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "test.settings.\(UUID().uuidString)")!
        sut = UserDefaultsSettingsRepository(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: defaults.description)
        defaults = nil
        sut = nil
        super.tearDown()
    }


    func test_load_returnsDefaults_whenNothingSaved() {
        let settings = sut.load()

        XCTAssertEqual(settings, AppSettings.default)
        XCTAssertEqual(settings.maxRouteDurationMinutes, 15)
    }


    func test_saveAndLoad_persistsMaxRouteDuration() {
        var settings = AppSettings.default
        settings.maxRouteDurationMinutes = 30

        sut.save(settings)
        let loaded = sut.load()

        XCTAssertEqual(loaded.maxRouteDurationMinutes, 30)
    }

    func test_save_overwritesPreviousValue() {
        var settings = AppSettings.default
        settings.maxRouteDurationMinutes = 20
        sut.save(settings)

        settings.maxRouteDurationMinutes = 45
        sut.save(settings)

        let loaded = sut.load()
        XCTAssertEqual(loaded.maxRouteDurationMinutes, 45)
    }


    func test_separateInstances_shareStorage_whenSameDefaults() {
        var settings = AppSettings.default
        settings.maxRouteDurationMinutes = 25
        sut.save(settings)

        let otherRepo = UserDefaultsSettingsRepository(defaults: defaults)
        let loaded = otherRepo.load()

        XCTAssertEqual(loaded.maxRouteDurationMinutes, 25)
    }
}
