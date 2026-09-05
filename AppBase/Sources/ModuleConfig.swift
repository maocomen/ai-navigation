import Foundation

/// 模块配置
public struct ModuleConfig: Sendable {
    public let minVersion: String
    public let maxVersion: String
    public let dependencies: [String]
    public let lazyLoad: Bool
    
    public init(
        minVersion: String = "1.0.0",
        maxVersion: String = "99.0.0",
        dependencies: [String] = [],
        lazyLoad: Bool = false
    ) {
        self.minVersion = minVersion
        self.maxVersion = maxVersion
        self.dependencies = dependencies
        self.lazyLoad = lazyLoad
    }
}
