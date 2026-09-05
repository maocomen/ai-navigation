import SwiftUI
import AppBase

// MARK: - 路由定义

public enum UserRoutes {

    public struct Login: RouteType {
        public static var path: String { "user/login" }
        public init() {}
        public static func == (lhs: Login, rhs: Login) -> Bool { true }
        public func hash(into hasher: inout Hasher) { hasher.combine("login") }
        @MainActor public func makeView() -> AnyView { AnyView(LoginView()) }
    }

    public struct Register: RouteType {
        public static var path: String { "user/register" }
        public init() {}
        public static func == (lhs: Register, rhs: Register) -> Bool { true }
        public func hash(into hasher: inout Hasher) { hasher.combine("register") }
        @MainActor public func makeView() -> AnyView { AnyView(RegisterView()) }
    }

    public struct Profile: RouteType {
        public static var path: String { "user/profile" }
        public let userID: String
        public init(userID: String) { self.userID = userID }
        public static func == (lhs: Profile, rhs: Profile) -> Bool { lhs.userID == rhs.userID }
        public func hash(into hasher: inout Hasher) { hasher.combine(userID) }
        @MainActor public func makeView() -> AnyView { AnyView(UserProfileView(userID: userID)) }
    }

    public struct Settings: RouteType {
        public static var path: String { "user/settings" }
        public init() {}
        public static func == (lhs: Settings, rhs: Settings) -> Bool { true }
        public func hash(into hasher: inout Hasher) { hasher.combine("settings") }
        @MainActor public func makeView() -> AnyView { AnyView(SettingsView()) }
    }
}

// MARK: - 模块

public final class UserModule: ModuleProtocol {
    public var moduleID: String { "com.app.user" }
    public var moduleName: String { "UserModule" }
    public init() {}

    public func registerRoutes(in registry: ModuleRegistry) {
        registry.addRoute(UserRoutes.Login())
        registry.addRoute(UserRoutes.Register())
        registry.addRoute(UserRoutes.Settings())
        registry.addRouteFactory("user/profile") { params in
            let userID = params["userID"] as? String ?? "user123"
            return UserRoutes.Profile(userID: userID)
        }
    }

    public func initializeResources() {
        UserRepository.shared.seedDemoUserIfNeeded()
    }

    public static func initialize() {
        ModuleRegistry.shared.registerModule(UserModule())
    }
}
