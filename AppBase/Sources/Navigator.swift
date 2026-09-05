import SwiftUI

/// 导航协议 - 跨模块导航抽象
public protocol Navigator: AnyObject {
    func push(_ route: any RouteType)
    func pop()
    func popToRoot()
    func replace(_ route: any RouteType)
    func navigate(to path: String)
    func navigate(to path: String, parameters: RouteParameters)
    var count: Int { get }
}

public extension Navigator {
    /// 按路由类型跳转（path 自动取自 `T.path`，避免裸字符串）
    func navigate<T: RouteType>(_ type: T.Type, parameters: RouteParameters = [:]) {
        navigate(to: T.path, parameters: parameters)
    }
}

// MARK: - Environment 支持

private struct NavigatorKey: EnvironmentKey {
    static let defaultValue: Navigator = EmptyNavigator()
}

public extension EnvironmentValues {
    var navigator: Navigator {
        get { self[NavigatorKey.self] }
        set { self[NavigatorKey.self] = newValue }
    }
}



/// 空导航器 - 无操作实现
private final class EmptyNavigator: Navigator {
    func push(_ route: any RouteType) {}
    func pop() {}
    func popToRoot() {}
    func replace(_ route: any RouteType) {}
    func navigate(to path: String) {}
    func navigate(to path: String, parameters: RouteParameters) {}
    var count: Int { 0 }
}
