import SwiftUI
import AppBase

// MARK: - 路由定义

public enum ProductRoutes {

    public struct List: RouteType {
        public static var path: String { "product/list" }
        public let category: String
        public init(category: String) { self.category = category }
        public static func == (lhs: List, rhs: List) -> Bool { lhs.category == rhs.category }
        public func hash(into hasher: inout Hasher) { hasher.combine(category) }
        @MainActor public func makeView() -> AnyView { AnyView(ProductListView(category: category)) }
    }

    public struct Detail: RouteType {
        public static var path: String { "product/detail" }
        public let productID: String
        public init(productID: String) { self.productID = productID }
        public static func == (lhs: Detail, rhs: Detail) -> Bool { lhs.productID == rhs.productID }
        public func hash(into hasher: inout Hasher) { hasher.combine(productID) }
        @MainActor public func makeView() -> AnyView { AnyView(ProductDetailView(productID: productID)) }
    }
}

// MARK: - 模块

public final class ProductModule: ModuleProtocol {
    public var moduleID: String { "com.app.product" }
    public var moduleName: String { "ProductModule" }
    public init() {}

    public func registerRoutes(in registry: ModuleRegistry) {
        registry.addRouteFactory("product/list") { params in
            let category = params["category"] as? String ?? "全部"
            return ProductRoutes.List(category: category)
        }
        registry.addRouteFactory("product/detail") { params in
            guard let productID = params["productID"] as? String else { return nil }
            return ProductRoutes.Detail(productID: productID)
        }
    }

    public func initializeResources() {}

    public static func initialize() {
        ModuleRegistry.shared.registerModule(ProductModule())
    }
}
