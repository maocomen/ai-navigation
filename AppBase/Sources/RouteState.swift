import Foundation

/// 路由操作类型
public enum RouteAction: String, Codable, Sendable {
    case push
    case pop
    case replace
    case reset
}

/// 路由状态
public struct RouteState: Sendable {
    public let path: String
    public let action: RouteAction
    public let timestamp: Date
    
    public init(path: String, action: RouteAction = .push) {
        self.path = path
        self.action = action
        self.timestamp = Date()
    }
}

/// 路由事件类型
public enum RouteEvent: Sendable {
    case willNavigate(to: String)
    case didNavigate(to: String)
    case willPop(from: String)
    case didPop(from: String)
    case failed(to: String, error: Error)
}

/// 路由事件处理闭包
public typealias RouteEventHandler = (RouteEvent) -> Void
