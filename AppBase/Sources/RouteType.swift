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

/// 路由栈元素包装 - 作为 `NavigationPath` 的统一元素类型
///
/// 说明：`NavigationPath` 会在栈中还原元素的**具体类型**，
/// 而 `navigationDestination(for:)` 也按**具体类型**匹配。
/// 若直接 `append(any RouteType)`，元素类型是各自的 `UserRoutes.Login` 等，
/// 与主应用注册的 `navigationDestination(for: RouteBox.self)` 无法匹配，
/// 导致二级页面无法展示。
/// 统一包装为 `RouteBox` 后，元素类型恒为 `RouteBox`，即可稳定匹配并动态解包到具体视图。
public struct RouteBox: Hashable, @unchecked Sendable {
    public typealias RouteViewBuilder = @MainActor (any RouteType) -> AnyView

    public let route: any RouteType

    public init(_ route: any RouteType) {
        self.route = route
    }

    public static func == (lhs: RouteBox, rhs: RouteBox) -> Bool {
        return AnyHashable(lhs.route) == AnyHashable(rhs.route)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(AnyHashable(route))
    }
}
