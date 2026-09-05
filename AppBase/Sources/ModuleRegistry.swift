import Foundation
import SwiftUI

/// 模块注册中心 - 全局单例
public final class ModuleRegistry: @unchecked Sendable {
    public static let shared = ModuleRegistry()

    private var modules: [String: (any ModuleProtocol)] = [:]
    private var routeInstances: [String: (any RouteType)] = [:]
    private var routeFactories: [String: RouteFactory] = [:]

    private init() {}

    /// 注册模块
    public func registerModule(_ module: any ModuleProtocol) {
        modules[module.moduleID] = module
        module.registerRoutes(in: self)
        module.initializeResources()
    }

    /// 注销模块
    public func unregisterModule(moduleID: String) {
        modules.removeValue(forKey: moduleID)
    }

    /// 获取模块
    public func getModule<T: ModuleProtocol>(_ type: T.Type) -> T? {
        return modules.values.compactMap { $0 as? T }.first
    }

    /// 检查模块是否已注册
    public func isModuleRegistered(_ moduleID: String) -> Bool {
        return modules.keys.contains(moduleID)
    }

    /// 添加无参路由
    public func addRoute<T: RouteType>(_ route: T) {
        routeInstances[T.path] = route
    }

    /// 注册带参路由工厂
    /// 通过字符串路由 + 参数构建具体路由实例
    public func addRouteFactory(_ path: String, factory: @escaping RouteFactory) {
        routeFactories[path] = factory
    }

    /// 判断路由是否存在
    public func containsRoute(_ path: String) -> Bool {
        return routeInstances[path] != nil || routeFactories[path] != nil
    }

    /// 解析路由 (无参)
    public func resolveRoute(for path: String) -> (any RouteType)? {
        return routeInstances[path]
    }

    /// 解析路由 (带参)
    /// 优先使用工厂根据参数构建；无工厂时回退到无参实例
    @MainActor
    public func resolveRoute(for path: String, parameters: RouteParameters) -> (any RouteType)? {
        if let factory = routeFactories[path] {
            return factory(parameters)
        }
        return routeInstances[path]
    }
}
