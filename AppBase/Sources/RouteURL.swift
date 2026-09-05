import Foundation

/// 路由 URL 解析器
///
/// ## URL 格式约定
/// ```
/// <scheme>://<module>/<action>?key1=value1&key2=value2
/// ```
/// - `scheme`：自定义固定 scheme（当前为 `navigate`），用于 App 内/外深度链接
/// - `path`：与 `RouteType.path` 对齐的「模块/动作」路径，如 `user/profile`
/// - `query`：路由参数，统一按 `[String: String]` 解析，具体类型由路由工厂二次转换
///
/// ## 示例
/// ```
/// navigate://user/login
/// navigate://user/profile?userID=u42
/// navigate://product/detail?productID=p3
/// navigate://order/cart
/// ```
public struct RouteURL: Sendable {

    /// 解析结果
    public struct Parsed: Sendable {
        /// 模块/动作 路径（与 RouteType.path 一致），如 "user/profile"
        public let path: String
        /// query 参数（已 URL 解码）
        public let parameters: [String: String]
    }

    /// 默认 scheme
    public static let defaultScheme = "navigate"

    /// 解析结果
    public let parsed: Parsed

    /// 从 URL 字符串解析
    /// - 不完整（缺 scheme）时自动补全为 `navigate://`
    /// - 路径格式：`module/action`（如 `user/login`）或 `navigate://module/action?key=value`
    public init?(string: String) {
        var text = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return nil }

        if text.contains("://") {
            guard let url = URL(string: text),
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                return nil
            }
            var parameters: [String: String] = [:]
            for item in components.queryItems ?? [] {
                parameters[item.name] = item.value ?? ""
            }
            let path = String(components.path.drop(while: { $0 == "/" }))
            self.init(parsed: Parsed(path: path, parameters: parameters))
        } else {
            if text.hasPrefix("/") { text.removeFirst() }
            let parts = text.split(separator: "?", maxSplits: 1)
            let pathPart = String(parts[0])
            var parameters: [String: String] = [:]
            if parts.count > 1 {
                for item in parts[1].split(separator: "&") {
                    let kv = item.split(separator: "=", maxSplits: 1)
                    if kv.count == 2 {
                        parameters[String(kv[0])] = String(kv[1])
                    }
                }
            }
            self.init(parsed: Parsed(path: pathPart, parameters: parameters))
        }
    }

    private init(parsed: Parsed) {
        self.parsed = parsed
    }

    /// 从 `URLComponents` 数据解析
    public init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        // path 去掉前导 "/"，拼成 "module/action"
        var path = String(components.path.drop(while: { $0 == "/" }))
        // 兼容 query 里缺省动作的情况
        if path.isEmpty {
            path = ""
        }

        var parameters: [String: String] = [:]
        for item in components.queryItems ?? [] {
            parameters[item.name] = item.value ?? ""
        }

        self.parsed = Parsed(path: path, parameters: parameters)
    }

    /// 模块/动作 路径
    public var path: String { parsed.path }
    /// 参数（String 形态）
    public var parameters: [String: String] { parsed.parameters }
}
