import Foundation

/// 路由 URL 解析错误
public enum RouteURLParseError: Error, Equatable, Sendable {
    /// 输入为空（或仅含空白字符）
    case empty
    /// scheme 不合法（当前仅支持 `navigate`）；URL 整体无法解析时也按此错误处理
    case invalidScheme(expected: String)
    /// host 不在 caller 白名单内（含 host 缺失的情况）
    case invalidHost(allowed: [String])
    /// path 为空（去掉前导 `/` 后没有「模块/动作」）
    case missingPath
}

/// 路由 URL 解析器
///
/// ## URL 格式约定
/// ```
/// navigate://<caller-host>/<module>/<action>?key1=value1&key2=value2
/// ```
/// - `scheme`：固定为 `navigate`，用于 App 内/外深度链接
/// - `host`：类域名形式，表示调用来源（caller），必须在 `Caller` 白名单内
/// - `path`：与 `RouteType.path` 对齐的「模块/动作」路径，如 `user/profile`
/// - `query`：路由参数，统一按 `[String: String]` 解析（值已 URL 解码），
///   具体类型可由 `value(for:as:)` 或路由工厂二次转换
///
/// ## 示例
/// ```
/// navigate://app.navigation.com/user/login
/// navigate://app.navigation.com/user/profile?userID=u42
/// navigate://external.navigation.com/product/detail?productID=p3
/// navigate://widget.navigation.com/order/cart
/// ```
///
/// ## 兼容纯路径写法（无 `://` 时默认 `caller = .app`）
/// ```
/// user/login
/// /user/login
/// user/login?userID=u42
/// ```
///
/// ## 设计说明
/// 省略 host 的 `navigate://user/login` 会被 `URLComponents` 拆成
/// `host=user` + `path=/login`（模块名被误当作 host），
/// 因此带 scheme 的 URL 必须显式携带 caller host；host 缺失或不在白名单内时解析失败。
public struct RouteURL: Sendable {

    /// 调用来源 - 以类域名 host 表示路由发起方
    public enum Caller: String, CaseIterable, Sendable {
        /// App 内部调用
        case app = "app.navigation.com"
        /// 外部 App 深度链接
        case external = "external.navigation.com"
        /// Web 页面跳转
        case web = "web.navigation.com"
        /// 推送通知
        case push = "push.navigation.com"
        /// 桌面 Widget
        case widget = "widget.navigation.com"
        /// Siri 语音
        case siri = "siri.navigation.com"

        /// caller 白名单（全部合法 host）
        public static let allHosts: [String] = allCases.map(\.rawValue)
    }

    /// 默认 scheme
    public static let defaultScheme = "navigate"

    /// 调用来源（从 URL host 提取；纯路径默认 `.app`）
    public let caller: Caller
    /// 模块/动作 路径（与 RouteType.path 一致），如 "user/profile"
    public let path: String
    /// query 参数（值已 URL 解码）
    public let parameters: [String: String]

    // MARK: - 解析

    /// 解析路由 URL 字符串
    ///
    /// - 纯路径（无 `://`）默认 `caller = .app`
    /// - 带 scheme 时校验 scheme 与 caller host 白名单
    public static func parse(_ string: String) -> Result<RouteURL, RouteURLParseError> {
        let text = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return .failure(.empty) }

        // 纯路径（无 scheme）：默认 App 内调用
        guard text.contains("://") else {
            return parsePurePath(text)
        }

        // 带 scheme：必须能构成合法 URL，否则按 scheme 不合法处理
        guard let components = URLComponents(string: text) else {
            return .failure(.invalidScheme(expected: defaultScheme))
        }
        return parse(components: components)
    }

    /// 从 URL 字符串解析（失败返回 nil，错误详情见 `parse(_:)`）
    ///
    /// - 纯路径（缺 scheme）默认 `caller = .app`
    /// - 路径格式：`module/action`（如 `user/login`）
    ///   或 `navigate://app.navigation.com/module/action?key=value`
    public init?(string: String) {
        guard case .success(let routeURL) = Self.parse(string) else {
            return nil
        }
        self = routeURL
    }

    /// 从 URL 解析
    /// - 校验 scheme 必须为 `navigate`、host 必须在 caller 白名单内
    /// - 从 host 提取 caller，从 path 提取「模块/动作」（去掉前导 `/`）
    public init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        guard case .success(let routeURL) = Self.parse(components: components) else {
            return nil
        }
        self = routeURL
    }

    init(caller: Caller, path: String, parameters: [String: String]) {
        self.caller = caller
        self.path = path
        self.parameters = parameters
    }

    // MARK: - 取值

    /// 按 key 取参数值并转换为指定类型（如 `Int`、`Bool`、`Double`）
    /// - 参数缺失或类型转换失败时返回 nil
    public func value<T: LosslessStringConvertible>(for key: String, as type: T.Type) -> T? {
        guard let rawValue = parameters[key] else { return nil }
        return T(rawValue)
    }

    // MARK: - 内部解析

    /// 纯路径解析（无 scheme，默认 caller = .app）
    private static func parsePurePath(_ text: String) -> Result<RouteURL, RouteURLParseError> {
        // 去掉前导 "/"，再在第一个 "?" 处切分 path 与 query
        let text = String(text.drop(while: { $0 == "/" }))
        let parts = text.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        let path = String(parts[0])
        guard !path.isEmpty else {
            return .failure(.missingPath)
        }
        let parameters = parts.count > 1 ? decodeQuery(String(parts[1])) : [:]
        return .success(RouteURL(caller: .app, path: path, parameters: parameters))
    }

    /// 从 URLComponents 解析（带 scheme 的完整 URL）
    private static func parse(components: URLComponents) -> Result<RouteURL, RouteURLParseError> {
        // scheme 校验
        guard components.scheme?.lowercased() == defaultScheme else {
            return .failure(.invalidScheme(expected: defaultScheme))
        }
        // host 校验：caller 白名单
        guard let host = components.host,
              let caller = Caller(rawValue: host.lowercased()) else {
            return .failure(.invalidHost(allowed: Caller.allHosts))
        }
        // path 去掉前导 "/"，拼成 "module/action"
        let path = String(components.path.drop(while: { $0 == "/" }))
        guard !path.isEmpty else {
            return .failure(.missingPath)
        }
        // query 保持 percent-encoded 原始形态，统一解码一次
        let parameters = decodeQuery(components.percentEncodedQuery)
        return .success(RouteURL(caller: caller, path: path, parameters: parameters))
    }

    /// 解析原始 query（percent-encoded 形态），key/value 统一做一次 `removingPercentEncoding`
    ///
    /// 注：不走 `URLComponents.queryItems`（其 name/value 已解码，再解一次会把
    /// `%25` 之类的合法转义二次解码），这里从原始形态统一解码一次。
    /// 解码失败（如非法的 `%` 序列）时回退为原始字符串。
    private static func decodeQuery(_ query: String?) -> [String: String] {
        guard let query, !query.isEmpty else { return [:] }
        var parameters: [String: String] = [:]
        for pair in query.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            // 跳过空 key 的退化 pair（如 "=v"）
            guard let rawKey = kv.first, !rawKey.isEmpty else { continue }
            let key = String(rawKey)
            let rawValue = kv.count > 1 ? String(kv[1]) : ""
            parameters[key.removingPercentEncoding ?? key] = rawValue.removingPercentEncoding ?? rawValue
        }
        return parameters
    }
}
