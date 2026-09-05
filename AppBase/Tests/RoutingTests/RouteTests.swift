import XCTest
@testable import AppBase

@available(macOS 13.0, iOS 16.0, *)
final class RouteTests: XCTestCase {
    func testRouteStateInitialization() throws {
        let state = RouteState(path: "user/login", action: .push)
        XCTAssertEqual(state.path, "user/login")
        XCTAssertEqual(state.action, .push)
        XCTAssertNotNil(state.timestamp)
    }
}
