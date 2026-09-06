import Foundation

/// 模块协议 - 所有模块必须遵守
public protocol ModuleProtocol: Sendable {
    /// 模块唯一标识
    var moduleID: String { get }
    
    /// 模块名称
    var moduleName: String { get }
    
    /// 注册路由到注册中心
    func registerRoutes(in registry: ModuleRegistry)
    
    /// 初始化模块资源
    func initializeResources()
}

/// 扩展：模块默认实现
public extension ModuleProtocol {
    func initializeResources() {}
}
