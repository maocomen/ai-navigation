import SwiftUI

/// 路由参数 - 字符串路由跳转时携带的弱类型参数
/// key 为参数名，value 为参数值（通常为 String/Int/Bool 等）
public typealias RouteParameters = [String: Any]

/// 路由工厂 - 根据参数构建路由实例
public typealias RouteFactory = @MainActor (RouteParameters) -> (any RouteType)?

/// 路由类型协议 - 所有路由必须遵守
public protocol RouteType: Hashable, Sendable {
    /// 路由路径 (用于日志和调试)
    static var path: String { get }

    /// 创建路由对应的视图
    /// 由模块自行实现，主应用无需感知具体路由类型
    @MainActor func makeView() -> AnyView
}

extension RouteType {
    /// 获取路径
    public var _path: String {
        return Self.path
    }
}
