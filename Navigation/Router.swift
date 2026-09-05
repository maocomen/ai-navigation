import SwiftUI
import AppBase

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
        p.append(route)
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
        p.append(route)
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

    // MARK: - 栈操作（作用于当前活跃 Tab）

    func replaceRoot(_ route: any RouteType) {
        var p = NavigationPath()
        p.append(route)
        setPath(p, for: activeTab)
        recordHistory(route._path, action: .reset)
    }

    func popToIndex(_ index: Int) {
        pop(to: index)
    }

    // MARK: - 便捷方法

    func goToLogin() { navigate(to: "user/login") }
    func goToProfile(userID: String = "user123") { navigate(to: "user/profile", parameters: ["userID": userID]) }
    func goToProductList(category: String = "全部") { navigate(to: "product/list", parameters: ["category": category]) }
    func goToProductDetail(productID: String) { navigate(to: "product/detail", parameters: ["productID": productID]) }
    func goToCart() { navigate(to: "order/cart") }
    func goToOrderList() { navigate(to: "order/list") }
    func goToOrderDetail(orderID: String) { navigate(to: "order/detail", parameters: ["orderID": orderID]) }

    func clearHistory() {
        history.removeAll()
    }

    // MARK: - 私有

    private func recordHistory(_ path: String, action: RouteAction) {
        history.append(RouteState(path: path, action: action))
    }
}
