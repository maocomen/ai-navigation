import SwiftUI

public protocol RouterProtocol: AnyObject {
    func push(_ route: any RouteType)
    func pop()
    func pop(to targetCount: Int)
    func popToRoot()
    func replace(_ route: any RouteType)
    func replaceRoot(_ route: any RouteType)
    func navigate(to pathString: String)
    @discardableResult func navigate(urlString: String) -> Bool
    @discardableResult func navigate(url: URL) -> Bool
    var count: Int { get }
    var historyEntries: [RouteState] { get }
    func clearHistory()
}

@Observable
@MainActor
public final class Router<Tab: Hashable>: RouterProtocol {

    public let allTabs: [Tab]
    public var activeTab: Tab
    public var tabLabels: [Tab: (name: String, icon: String)] = [:]

    private var paths: [Tab: NavigationPath] = [:]
    private var pathMirrors: [Tab: [String]] = [:]
    private var history: [RouteState] = []
    private let registry = ModuleRegistry.shared

    public init(tabs: [Tab], activeTab: Tab) {
        self.allTabs = tabs
        self.activeTab = activeTab
        for tab in tabs { paths[tab] = NavigationPath() }
    }

    // MARK: - 栈绑定

    public func binding(for tab: Tab) -> Binding<NavigationPath> {
        Binding(
            get: { self.paths[tab] ?? NavigationPath() },
            set: { self.setPath($0, for: tab) }
        )
    }

    public func isDetail(_ tab: Tab) -> Bool {
        !(paths[tab]?.isEmpty ?? true)
    }

    private func setPath(_ newPath: NavigationPath, for tab: Tab) {
        paths[tab] = newPath
        let diff = (pathMirrors[tab] ?? []).count - newPath.count
        if diff > 0 { pathMirrors[tab]?.removeLast(diff) }
    }

    // MARK: - 栈信息

    public var count: Int { paths[activeTab]?.count ?? 0 }

    public func stackPaths(for tab: Tab) -> [String] {
        pathMirrors[tab] ?? []
    }

    public var stackDescription: String {
        let p = stackPaths(for: activeTab)
        guard !p.isEmpty else { return "(空)" }
        return p.joined(separator: " → ")
    }

    public var historyEntries: [RouteState] { history }

    // MARK: - 导航操作

    public func push(_ route: any RouteType) {
        var p = paths[activeTab] ?? NavigationPath()
        p.append(RouteBox(route))
        setPath(p, for: activeTab)
        pathMirrors[activeTab, default: []].append(route._path)
        recordHistory(route._path, action: .push)
    }

    public func pop() {
        var p = paths[activeTab] ?? NavigationPath()
        guard !p.isEmpty else { return }
        p.removeLast()
        setPath(p, for: activeTab)
    }

    public func pop(to targetCount: Int) {
        var p = paths[activeTab] ?? NavigationPath()
        guard targetCount >= 0 && targetCount < p.count else { return }
        p.removeLast(p.count - targetCount)
        setPath(p, for: activeTab)
    }

    public func popToRoot() {
        var p = paths[activeTab] ?? NavigationPath()
        p.removeLast(p.count)
        setPath(p, for: activeTab)
    }

    public func replace(_ route: any RouteType) {
        var p = paths[activeTab] ?? NavigationPath()
        guard !p.isEmpty else { push(route); return }
        p.removeLast()
        p.append(RouteBox(route))
        setPath(p, for: activeTab)
        if !(pathMirrors[activeTab] ?? []).isEmpty { pathMirrors[activeTab]?.removeLast() }
        pathMirrors[activeTab, default: []].append(route._path)
        recordHistory(route._path, action: .replace)
    }

    public func replaceRoot(_ route: any RouteType) {
        var p = NavigationPath()
        p.append(RouteBox(route))
        setPath(p, for: activeTab)
        pathMirrors[activeTab] = [route._path]
        recordHistory(route._path, action: .reset)
    }

    public func popToIndex(_ index: Int) { pop(to: index) }

    // MARK: - URL 导航

    public func navigate(to pathString: String) {
        navigate(to: pathString, parameters: [:])
    }

    public func navigate(to pathString: String, parameters: RouteParameters) {
        let stringParams = parameters.compactMapValues { $0 as? String }
        navigateCore(to: pathString, parameters: stringParams, caller: .app)
    }

    public func navigate<T: RouteType>(_ type: T.Type, parameters: RouteParameters = [:]) {
        navigate(to: T.path, parameters: parameters)
    }

    @discardableResult
    public func navigate(url: URL) -> Bool {
        navigate(parsed: RouteURL.parse(url.absoluteString))
    }

    @discardableResult
    public func navigate(urlString: String) -> Bool {
        navigate(parsed: RouteURL.parse(urlString))
    }

    private func navigate(parsed: Result<RouteURL, RouteURLParseError>) -> Bool {
        switch parsed {
        case .success(let url):
            return navigateCore(to: url.path, parameters: url.parameters, caller: url.caller)
        case .failure(let error):
            print("[Router] URL parse failed: \(error)")
            return false
        }
    }

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
        guard let route = registry.resolveRoute(for: path, parameters: parameters) else { return false }
        push(route)
        return true
    }

    // MARK: - 调试

    public func clearHistory() { history.removeAll() }

    private func recordHistory(_ path: String, action: RouteAction) {
        history.append(RouteState(path: path, action: action))
    }
}

// MARK: - AnyRouter（类型擦除，供业务模块使用）

@Observable
@MainActor
public final class AnyRouter {
    private let _push: (any RouteType) -> Void
    private let _pop: () -> Void
    private let _popTo: (Int) -> Void
    private let _popToRoot: () -> Void
    private let _replace: (any RouteType) -> Void
    private let _replaceRoot: (any RouteType) -> Void
    private let _navigateString: (String) -> Void
    private let _navigateURL: (URL) -> Bool
    private let _navigateURLString: (String) -> Bool
    private let _count: () -> Int
    private let _historyEntries: () -> [RouteState]
    private let _clearHistory: () -> Void

    public init<R: RouterProtocol>(_ router: R) {
        self._push = { router.push($0) }
        self._pop = { router.pop() }
        self._popTo = { router.pop(to: $0) }
        self._popToRoot = { router.popToRoot() }
        self._replace = { router.replace($0) }
        self._replaceRoot = { router.replaceRoot($0) }
        self._navigateString = { router.navigate(to: $0) }
        self._navigateURL = { router.navigate(url: $0) }
        self._navigateURLString = { router.navigate(urlString: $0) }
        self._count = { router.count }
        self._historyEntries = { router.historyEntries }
        self._clearHistory = { router.clearHistory() }
    }

    public func push(_ route: any RouteType) { _push(route) }
    public func pop() { _pop() }
    public func pop(to targetCount: Int) { _popTo(targetCount) }
    public func popToRoot() { _popToRoot() }
    public func replace(_ route: any RouteType) { _replace(route) }
    public func replaceRoot(_ route: any RouteType) { _replaceRoot(route) }
    public func navigate(to pathString: String) { _navigateString(pathString) }
    @discardableResult public func navigate(url: URL) -> Bool { _navigateURL(url) }
    @discardableResult public func navigate(urlString: String) -> Bool { _navigateURLString(urlString) }
    public var count: Int { _count() }
    public var historyEntries: [RouteState] { _historyEntries() }
    public func clearHistory() { _clearHistory() }
}
