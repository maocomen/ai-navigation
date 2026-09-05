import Foundation

/// AppBase 基础类
public class AppBase {
    public init() {}
    
    /// 示例方法
    public func greet() -> String {
        return "Hello from AppBase!"
    }
}

/// 配置管理类
public class AppConfig {
    public static let shared = AppConfig()
    
    public var appName: String = "MyApp"
    public var version: String = "1.0.0"
    
    private init() {}
}
