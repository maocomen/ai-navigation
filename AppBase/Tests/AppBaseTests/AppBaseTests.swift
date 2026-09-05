import XCTest
@testable import AppBase

final class AppBaseTests: XCTestCase {
    func testExample() throws {
        let base = AppBase()
        XCTAssertEqual(base.greet(), "Hello from AppBase!")
    }

    func testConfig() throws {
        let config = AppConfig.shared
        XCTAssertEqual(config.appName, "MyApp")
        XCTAssertEqual(config.version, "1.0.0")
    }
}
