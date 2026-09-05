import SwiftUI
import AppBase
import UserModule
import ProductModule
import OrderModule

@Observable
@MainActor
final class Router: Navigator {

    enum Tab: String, CaseIterable, Hashable, Sendable {
        case home, product, order, profile
    }

    /// 当前活跃的 Tab，由 ContentView 在切换时同步
    var activeTab: Tab = .home

    /// 各 Tab 独立导航栈
    private(set) var homePath = NavigationPath()
    private(set) var productPath = NavigationPath()
    private(set) var orderPath = NavigationPath()
    private(set) var profilePath = NavigationPath()

    private var history: [RouteState] = []
    private let registry = ModuleRegistry.shared

    init() {}

    // MARK: - 栈绑定

    /// 获取指定 Tab 的路径绑定，供各 Tab 的 NavigationStack 使用
    func binding(for tab: Tab) -> Binding<NavigationPath> {
        Binding(
            get: { self.path(for: tab) },
            set: { self.setPath($0, for: tab) }
        )
    }

    /// 指定 Tab 是否处于二级页（栈非空），用于驱动 TabBar 显隐
    func isDetail(_ tab: Tab) -> Bool {
        !path(for: tab).isEmpty
    }

    private func path(for tab: Tab) -> NavigationPath {
        switch tab {
        case .home: return homePath
        case .product: return productPath
        case .order: return orderPath
        case .profile: return profilePath
        }
    }

    private func setPath(_ newPath: NavigationPath, for tab: Tab) {
        switch tab {
        case .home: homePath = newPath
        case .product: productPath = newPath
        case .order: orderPath = newPath
        case .profile: profilePath = newPath
        }
    }

    // MARK: - 当前活跃栈信息

    var count: Int { path(for: activeTab).count }

    var stackDescription: String {
        guard count > 0 else { return "(空)" }
        return (0..<count).map { "[$\($0)]" }.joined(separator: " → ")
    }

    var historyEntries: [RouteState] { history }

    // MARK: - Navigator 协议

    func push(_ route: any RouteType) {
        var p = path(for: activeTab)
        p.append(RouteBox(route))
        setPath(p, for: activeTab)
        recordHistory(route._path, action: .push)
    }

    func pop() {
        var p = path(for: activeTab)
        guard !p.isEmpty else { return }
        p.removeLast()
        setPath(p, for: activeTab)
    }

    func pop(to targetCount: Int) {
        var p = path(for: activeTab)
        guard targetCount >= 0 && targetCount < p.count else { return }
        p.removeLast(p.count - targetCount)
        setPath(p, for: activeTab)
    }

    func popToRoot() {
        var p = path(for: activeTab)
        p.removeLast(p.count)
        setPath(p, for: activeTab)
    }

    func replace(_ route: any RouteType) {
        var p = path(for: activeTab)
        guard !p.isEmpty else {
            push(route)
            return
        }
        p.removeLast()
        p.append(RouteBox(route))
        setPath(p, for: activeTab)
        recordHistory(route._path, action: .replace)
    }

    func navigate(to pathString: String) {
        navigate(to: pathString, parameters: [:])
    }

    func navigate(to pathString: String, parameters: RouteParameters) {
        if let route = registry.resolveRoute(for: pathString, parameters: parameters) {
            push(route)
        }
    }

    /// 通过 URL 跳转（深度链接入口）
    /// - 返回 `true` 表示成功跳转，`false` 表示 URL 无效或路由未找到
    @discardableResult
    func navigate(url: URL) -> Bool {
        guard let routeURL = RouteURL(url: url) else { return false }
        return navigateCore(to: routeURL.path, parameters: routeURL.parameters)
    }

    /// 通过 URL 字符串跳转
    /// - 返回 `true` 表示成功跳转，`false` 表示 URL 无效或路由未找到
    @discardableResult
    func navigate(urlString: String) -> Bool {
        guard let routeURL = RouteURL(string: urlString) else { return false }
        return navigateCore(to: routeURL.path, parameters: routeURL.parameters)
    }

    /// 核心跳转：路径 + 参数（参数以 String 为值，交由工厂二次解析类型）
    @discardableResult
    private func navigateCore(to path: String, parameters: [String: String]) -> Bool {
        guard let route = registry.resolveRoute(for: path, parameters: parameters) else {
            return false
        }
        push(route)
        return true
    }

    // MARK: - 栈操作（作用于当前活跃 Tab）

    func replaceRoot(_ route: any RouteType) {
        var p = NavigationPath()
        p.append(RouteBox(route))
        setPath(p, for: activeTab)
        recordHistory(route._path, action: .reset)
    }

    func popToIndex(_ index: Int) {
        pop(to: index)
    }

    // MARK: - 便捷方法

    func goToLogin() { navigate(UserRoutes.Login.self) }
    func goToProfile(userID: String = "user123") { navigate(UserRoutes.Profile.self, parameters: ["userID": userID]) }
    func goToProductList(category: String = "全部") { navigate(ProductRoutes.List.self, parameters: ["category": category]) }
    func goToProductDetail(productID: String) { navigate(ProductRoutes.Detail.self, parameters: ["productID": productID]) }
    func goToCart() { navigate(OrderRoutes.Cart.self) }
    func goToOrderList() { navigate(OrderRoutes.List.self) }
    func goToOrderDetail(orderID: String) { navigate(OrderRoutes.Detail.self, parameters: ["orderID": orderID]) }

    func clearHistory() {
        history.removeAll()
    }

    // MARK: - 私有

    private func recordHistory(_ path: String, action: RouteAction) {
        history.append(RouteState(path: path, action: action))
    }
}
