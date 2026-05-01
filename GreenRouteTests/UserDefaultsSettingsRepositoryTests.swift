// Verifies that UserDefaultsSettingsRepository correctly persists and retrieves
// AppSettings values. Each test uses an isolated UserDefaults suite to avoid
// polluting shared state between runs.

import XCTest
import GreenRouteDomain
@testable import GreenRouteData

final class UserDefaultsSettingsRepositoryTests: XCTestCase {

    private var sut: UserDefaultsSettingsRepository!
    /// Isolated UserDefaults suite created fresh for each test and cleaned up in tearDown.
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // Use a unique suite name per test to guarantee complete isolation.
        defaults = UserDefaults(suiteName: "test.settings.\(UUID().uuidString)")!
        sut = UserDefaultsSettingsRepository(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: defaults.description)
        defaults = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Default values

    /// When nothing has been persisted, load() should return the application-defined defaults.
    func test_load_returnsDefaults_whenNothingSaved() {
        let settings = sut.load()

        XCTAssertEqual(settings, AppSettings.default)
        XCTAssertEqual(settings.maxRouteDurationMinutes, 15)
    }

    // MARK: - Round-trip persistence

    /// Saving a modified setting and immediately loading should return the saved value.
    func test_saveAndLoad_persistsMaxRouteDuration() {
        var settings = AppSettings.default
        settings.maxRouteDurationMinutes = 30

        sut.save(settings)
        let loaded = sut.load()

        XCTAssertEqual(loaded.maxRouteDurationMinutes, 30)
    }

    /// A second save with a different value should overwrite the first, not append.
    func test_save_overwritesPreviousValue() {
        var settings = AppSettings.default
        settings.maxRouteDurationMinutes = 20
        sut.save(settings)

        settings.maxRouteDurationMinutes = 45
        sut.save(settings)

        let loaded = sut.load()
        XCTAssertEqual(loaded.maxRouteDurationMinutes, 45)
    }

    // MARK: - Shared storage

    /// Two repository instances backed by the same UserDefaults suite should see each other's writes.
    func test_separateInstances_shareStorage_whenSameDefaults() {
        var settings = AppSettings.default
        settings.maxRouteDurationMinutes = 25
        sut.save(settings)

        let otherRepo = UserDefaultsSettingsRepository(defaults: defaults)
        let loaded = otherRepo.load()

        XCTAssertEqual(loaded.maxRouteDurationMinutes, 25)
    }
}
