import Foundation

/// 轻量依赖注入容器 - 实现「协议/实现分离」的跨模块服务共享
///
/// 与 `ModuleRegistry`（管路由）职责互补：`ServiceContainer` 管**服务**。
/// 服务提供方按协议类型注册实现，消费方按协议类型解析，
/// 使调用方只依赖协议、不依赖具体实现类。
///
/// ```swift
/// // 提供方（OrderModule 初始化时）
/// ServiceContainer.shared.register(CartService.self, instance: CartServiceImpl.shared)
///
/// // 消费方（ProductModule）
/// guard let cart = ServiceContainer.shared.resolve(CartService.self) else { return }
/// cart.addItem(...)
/// ```
public final class ServiceContainer: @unchecked Sendable {
    public static let shared = ServiceContainer()

    private var services: [String: Any] = [:]
    private let lock = NSLock()

    private init() {}

    /// 注册服务实现（按协议类型）
    public func register<P>(_ protocolType: P.Type, instance: P) {
        lock.lock(); defer { lock.unlock() }
        services[key(for: protocolType)] = instance
    }

    /// 解析服务（按协议类型），未注册返回 nil
    public func resolve<P>(_ protocolType: P.Type) -> P? {
        lock.lock(); defer { lock.unlock() }
        return services[key(for: protocolType)] as? P
    }

    /// 移除服务
    public func unregister<P>(_ protocolType: P.Type) {
        lock.lock(); defer { lock.unlock() }
        services.removeValue(forKey: key(for: protocolType))
    }

    private func key<P>(for type: P.Type) -> String {
        return String(reflecting: type)
    }
}
