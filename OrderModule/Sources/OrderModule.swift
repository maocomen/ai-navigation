import SwiftUI
import AppBase
import OrderContracts

// MARK: - 路由定义

public enum OrderRoutes {

    public struct Cart: RouteType {
        public static var path: String { OrderLinks.cart }
        public init() {}
        public static func == (lhs: Cart, rhs: Cart) -> Bool { true }
        public func hash(into hasher: inout Hasher) { hasher.combine("cart") }
        @MainActor public func makeView() -> AnyView { AnyView(CartView()) }
    }

    public struct List: RouteType {
        public static var path: String { OrderLinks.list }
        public init() {}
        public static func == (lhs: List, rhs: List) -> Bool { true }
        public func hash(into hasher: inout Hasher) { hasher.combine("orderlist") }
        @MainActor public func makeView() -> AnyView { AnyView(OrderListView()) }
    }

    public struct Detail: RouteType {
        public static var path: String { OrderLinks.detail }
        public let orderID: String
        public init(orderID: String) { self.orderID = orderID }
        public static func == (lhs: Detail, rhs: Detail) -> Bool { lhs.orderID == rhs.orderID }
        public func hash(into hasher: inout Hasher) { hasher.combine(orderID) }
        @MainActor public func makeView() -> AnyView { AnyView(OrderDetailView(orderID: orderID)) }
    }

    public struct Checkout: RouteType {
        public static var path: String { OrderLinks.checkout }
        public init() {}
        public static func == (lhs: Checkout, rhs: Checkout) -> Bool { true }
        public func hash(into hasher: inout Hasher) { hasher.combine("checkout") }
        @MainActor public func makeView() -> AnyView { AnyView(CheckoutView()) }
    }
}

// MARK: - 模块

public final class OrderModule: ModuleProtocol {
    public var moduleID: String { "com.app.order" }
    public var moduleName: String { "OrderModule" }
    public init() {}

    public func registerRoutes(in registry: ModuleRegistry) {
        registry.addRoute(OrderRoutes.Cart())
        registry.addRoute(OrderRoutes.List())
        registry.addRoute(OrderRoutes.Checkout())
        registry.addRouteFactory(OrderRoutes.Detail.self) { params in
            guard let orderID = params["orderID"] as? String else { return nil }
            return OrderRoutes.Detail(orderID: orderID)
        }
    }

    public func initializeResources() {
        let cart = MainActor.assumeIsolated { CartServiceImpl.shared }
        ServiceContainer.shared.register(CartService.self, instance: cart)
    }

    public static func initialize() {
        ModuleRegistry.shared.registerModule(OrderModule())
    }
}
