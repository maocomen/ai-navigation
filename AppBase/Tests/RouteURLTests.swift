import XCTest
@testable import AppBase

/// RouteURL.parse(_:) 解析行为测试
///
/// 覆盖：
/// - 新格式 `navigate://<caller-host>/<module>/<action>?key=value`（全部 caller）
/// - 旧纯路径格式兼容（`user/login`、`/user/login`、带 query）
/// - 错误情况（empty / invalidScheme / invalidHost / missingPath）
/// - 特殊字符参数（中文解码、单次解码保证）与泛型取值
final class RouteURLTests: XCTestCase {

    // MARK: - 辅助

    /// RouteURL 未实现 Equatable，无法直接比较 Result；拆出成功值便于断言
    private func success(_ result: Result<RouteURL, RouteURLParseError>) -> RouteURL? {
        guard case .success(let routeURL) = result else { return nil }
        return routeURL
    }

    /// 拆出错误值（RouteURLParseError 为 Equatable，可直接比较）
    private func failure(_ result: Result<RouteURL, RouteURLParseError>) -> RouteURLParseError? {
        guard case .failure(let error) = result else { return nil }
        return error
    }

    // MARK: - 纯路径（旧格式兼容）

    func testParsePurePath() {
        // 无前导 "/"
        let plain = success(RouteURL.parse("user/login"))
        XCTAssertNotNil(plain)
        XCTAssertEqual(plain?.caller, .app)
        XCTAssertEqual(plain?.path, "user/login")
        XCTAssertEqual(plain?.parameters.count, 0)

        // 带前导 "/"，path 应去掉前导斜杠
        let leadingSlash = success(RouteURL.parse("/user/login"))
        XCTAssertNotNil(leadingSlash)
        XCTAssertEqual(leadingSlash?.caller, .app)
        XCTAssertEqual(leadingSlash?.path, "user/login")
    }

    func testParsePurePathWithQuery() {
        let routeURL = success(RouteURL.parse("user/login?userID=u42&name=Tom"))
        XCTAssertNotNil(routeURL)
        XCTAssertEqual(routeURL?.caller, .app)
        XCTAssertEqual(routeURL?.path, "user/login")
        XCTAssertEqual(routeURL?.parameters["userID"], "u42")
        XCTAssertEqual(routeURL?.parameters["name"], "Tom")
        XCTAssertEqual(routeURL?.parameters.count, 2)
    }

    // MARK: - 完整 URL（新格式）

    func testParseFullURL() {
        let routeURL = success(RouteURL.parse("navigate://app.navigation.com/user/login"))
        XCTAssertNotNil(routeURL)
        XCTAssertEqual(routeURL?.caller, .app)
        XCTAssertEqual(routeURL?.path, "user/login")
        XCTAssertEqual(routeURL?.parameters.count, 0)
    }

    func testParseExternalCaller() {
        let routeURL = success(RouteURL.parse("navigate://external.navigation.com/user/profile?userID=u42"))
        XCTAssertNotNil(routeURL)
        XCTAssertEqual(routeURL?.caller, .external)
        XCTAssertEqual(routeURL?.path, "user/profile")
        XCTAssertEqual(routeURL?.parameters["userID"], "u42")
    }

    func testParseWebCaller() {
        let routeURL = success(RouteURL.parse("navigate://web.navigation.com/product/detail?productID=p3"))
        XCTAssertNotNil(routeURL)
        XCTAssertEqual(routeURL?.caller, .web)
        XCTAssertEqual(routeURL?.path, "product/detail")
        XCTAssertEqual(routeURL?.parameters["productID"], "p3")
    }

    func testParsePushCaller() {
        let routeURL = success(RouteURL.parse("navigate://push.navigation.com/order/detail?orderID=ORD-123"))
        XCTAssertNotNil(routeURL)
        XCTAssertEqual(routeURL?.caller, .push)
        XCTAssertEqual(routeURL?.path, "order/detail")
        XCTAssertEqual(routeURL?.parameters["orderID"], "ORD-123")
    }

    func testParseWidgetCaller() {
        let routeURL = success(RouteURL.parse("navigate://widget.navigation.com/order/list"))
        XCTAssertNotNil(routeURL)
        XCTAssertEqual(routeURL?.caller, .widget)
        XCTAssertEqual(routeURL?.path, "order/list")
    }

    func testParseSiriCaller() {
        let routeURL = success(RouteURL.parse("navigate://siri.navigation.com/user/settings"))
        XCTAssertNotNil(routeURL)
        XCTAssertEqual(routeURL?.caller, .siri)
        XCTAssertEqual(routeURL?.path, "user/settings")
    }

    // MARK: - 大小写不敏感

    func testCaseInsensitiveSchemeAndHost() {
        let routeURL = success(RouteURL.parse("NAVIGATE://APP.NAVIGATION.COM/user/login"))
        XCTAssertNotNil(routeURL)
        XCTAssertEqual(routeURL?.caller, .app)
        XCTAssertEqual(routeURL?.path, "user/login")
    }

    // MARK: - 特殊字符参数

    func testChineseParameterDecoding() {
        // %E5%85%A8%E9%83%A8 是 "全部" 的 UTF-8 percent-encoding
        let routeURL = success(RouteURL.parse("product/detail?category=%E5%85%A8%E9%83%A8"))
        XCTAssertNotNil(routeURL)
        XCTAssertEqual(routeURL?.parameters["category"], "全部")
    }

    func testNoDoubleDecoding() {
        // %25 是 "%" 的合法转义：只解码一次应得 "100%"；双重解码会错误地得到 "100"
        let routeURL = success(RouteURL.parse("product/detail?text=100%25"))
        XCTAssertNotNil(routeURL)
        XCTAssertEqual(routeURL?.parameters["text"], "100%")
    }

    // MARK: - 泛型取值

    func testValueGenericAccessor() {
        let routeURL = success(RouteURL.parse("product/list?count=3&enabled=true&name=abc"))
        XCTAssertNotNil(routeURL)

        XCTAssertEqual(routeURL?.value(for: "count", as: Int.self), 3)
        XCTAssertEqual(routeURL?.value(for: "enabled", as: Bool.self), true)
        XCTAssertEqual(routeURL?.value(for: "name", as: String.self), "abc")

        // key 不存在 → nil
        XCTAssertNil(routeURL?.value(for: "missing", as: Int.self))
        // 类型转换失败 → nil（"abc" 不是 Int）
        XCTAssertNil(routeURL?.value(for: "name", as: Int.self))
    }

    // MARK: - 错误情况

    func testEmptyInput() {
        XCTAssertEqual(failure(RouteURL.parse("")), .empty)
        // 仅空白字符同样视为空输入
        XCTAssertEqual(failure(RouteURL.parse("   \n\t")), .empty)
    }

    func testInvalidScheme() {
        XCTAssertEqual(
            failure(RouteURL.parse("ftp://app.navigation.com/user/login")),
            .invalidScheme(expected: RouteURL.defaultScheme)
        )
    }

    func testInvalidHost() {
        // 旧格式 navigate://user/login 会被 URLComponents 拆成 host=user + path=/login，
        // host 不在 caller 白名单内必须 fail loud
        XCTAssertEqual(
            failure(RouteURL.parse("navigate://user/login")),
            .invalidHost(allowed: RouteURL.Caller.allHosts)
        )
    }

    func testMissingPath() {
        XCTAssertEqual(
            failure(RouteURL.parse("navigate://app.navigation.com/")),
            .missingPath
        )
    }
}
