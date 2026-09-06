import SwiftUI

/// 路由器 - 运行时导航引擎
///
/// 负责：
/// - 实现跨模块导航（push/pop/replace/navigate）
/// - 多 Tab 独立导航栈管理
/// - 字符串路由 → 类型化 Route 的桥梁
///
/// 业务模块通过 `@Environment(Router.self)` 获取实例，
/// 无需依赖任何业务模块类型。
@Observable
@MainActor
public final class Router {

    public enum Tab: String, CaseIterable, Hashable, Sendable {
        case home, product, order, profile
    }

    /// 当前活跃的 Tab，由 ContentView 在切换时同步
    public var activeTab: Tab = .home

    /// 各 Tab 独立导航栈
    public private(set) var homePath = NavigationPath()
    public private(set) var productPath = NavigationPath()
    public private(set) var orderPath = NavigationPath()
    public private(set) var profilePath = NavigationPath()

    private var history: [RouteState] = []
    private let registry = ModuleRegistry.shared

    public nonisolated init() {}

    // MARK: - 栈绑定

    /// 获取指定 Tab 的路径绑定，供各 Tab 的 NavigationStack 使用
    public func binding(for tab: Tab) -> Binding<NavigationPath> {
        Binding(
            get: { self.path(for: tab) },
            set: { self.setPath($0, for: tab) }
        )
    }

    /// 指定 Tab 是否处于二级页（栈非空），用于驱动 TabBar 显隐
    public func isDetail(_ tab: Tab) -> Bool {
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

    public var count: Int { path(for: activeTab).count }

    public var stackDescription: String {
        guard count > 0 else { return "(空)" }
        return (0..<count).map { "[$\($0)]" }.joined(separator: " → ")
    }

    public var historyEntries: [RouteState] { history }

    // MARK: - 导航操作

    public func push(_ route: any RouteType) {
        var p = path(for: activeTab)
        p.append(RouteBox(route))
        setPath(p, for: activeTab)
        recordHistory(route._path, action: .push)
    }

    public func pop() {
        var p = path(for: activeTab)
        guard !p.isEmpty else { return }
        p.removeLast()
        setPath(p, for: activeTab)
    }

    public func pop(to targetCount: Int) {
        var p = path(for: activeTab)
        guard targetCount >= 0 && targetCount < p.count else { return }
        p.removeLast(p.count - targetCount)
        setPath(p, for: activeTab)
    }

    public func popToRoot() {
        var p = path(for: activeTab)
        p.removeLast(p.count)
        setPath(p, for: activeTab)
    }

    public func replace(_ route: any RouteType) {
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

    public func navigate(to pathString: String) {
        navigate(to: pathString, parameters: [:])
    }

    /// 通过路径字符串 + 参数跳转（App 内调用，caller 视为 `.app`）
    ///
    /// `RouteParameters` 值为 `Any`，此处收窄为 `[String: String]` 以对齐 `navigateCore`，
    /// 非 String 值会被过滤（现有调用方均传 String 值或空参数）。
    public func navigate(to pathString: String, parameters: RouteParameters) {
        let stringParameters = parameters.compactMapValues { $0 as? String }
        navigateCore(to: pathString, parameters: stringParameters, caller: .app)
    }

    /// 按路由类型跳转，path 自动取自 `T.path`，避免裸字符串
    public func navigate<T: RouteType>(_ type: T.Type, parameters: RouteParameters = [:]) {
        navigate(to: T.path, parameters: parameters)
    }

    /// 通过 URL 跳转（深度链接入口）
    /// - 返回 `true` 表示成功跳转，`false` 表示 URL 无效或路由未找到
    /// - 解析失败时打印错误原因到控制台
    @discardableResult
    public func navigate(url: URL) -> Bool {
        navigate(parsed: RouteURL.parse(url.absoluteString))
    }

    /// 通过 URL 字符串跳转
    /// - 返回 `true` 表示成功跳转，`false` 表示 URL 无效或路由未找到
    /// - 解析失败时打印错误原因到控制台
    @discardableResult
    public func navigate(urlString: String) -> Bool {
        navigate(parsed: RouteURL.parse(urlString))
    }

    /// 深度链接统一入口：解析成功携带 caller 走核心跳转，失败打印错误原因并返回 false
    private func navigate(parsed: Result<RouteURL, RouteURLParseError>) -> Bool {
        switch parsed {
        case .success(let routeURL):
            return navigateCore(
                to: routeURL.path,
                parameters: routeURL.parameters,
                caller: routeURL.caller
            )
        case .failure(let error):
            print("[Router] URL parse failed: \(error)")
            return false
        }
    }

    /// 核心跳转：路径 + 参数 + 调用来源（参数以 String 为值，交由工厂二次解析类型）
    ///
    /// caller 策略钩子（第一阶段仅打印日志，不改变实际导航行为）：
    /// - `.external` / `.web`：外部来源，记录来源日志（后续可加安全校验/降级策略）
    /// - `.push`：推送来源，记录日志（后续可加去重/落地页策略）
    /// - `.app` / `.widget` / `.siri`：App 受信来源，直接跳转
    @discardableResult
    private func navigateCore(to path: String, parameters: [String: String], caller: RouteURL.Caller) -> Bool {
        switch caller {
        case .external, .web:
            print("[Router] external/web deep link: \(path) from \(caller.rawValue)")
        case .push:
            print("[Router] push deep link: \(path)")
        case .app, .widget, .siri:
            break
        }
        guard let route = registry.resolveRoute(for: path, parameters: parameters) else {
            return false
        }
        push(route)
        return true
    }

    // MARK: - 栈操作（作用于当前活跃 Tab）

    public func replaceRoot(_ route: any RouteType) {
        var p = NavigationPath()
        p.append(RouteBox(route))
        setPath(p, for: activeTab)
        recordHistory(route._path, action: .reset)
    }

    public func popToIndex(_ index: Int) {
        pop(to: index)
    }

    // MARK: - 调试

    public func clearHistory() {
        history.removeAll()
    }

    private func recordHistory(_ path: String, action: RouteAction) {
        history.append(RouteState(path: path, action: action))
    }
}

// MARK: - Environment 支持

private struct RouterKey: EnvironmentKey {
    static let defaultValue: Router = Router()
}

public extension EnvironmentValues {
    var router: Router {
        get { self[RouterKey.self] }
        set { self[RouterKey.self] = newValue }
    }
}
