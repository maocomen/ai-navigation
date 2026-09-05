import SwiftUI
import AppBase

// MARK: - 商品数据模型

public struct Product: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let price: Double
    public let category: String
    public let icon: String

    public init(id: String, name: String, price: Double, category: String, icon: String) {
        self.id = id
        self.name = name
        self.price = price
        self.category = category
        self.icon = icon
    }
}

public struct ProductData {
    public static let products: [Product] = [
        Product(id: "p1", name: "MacBook Pro 16\"", price: 19999, category: "电脑", icon: "laptopcomputer"),
        Product(id: "p2", name: "iPhone 17 Pro", price: 8999, category: "手机", icon: "iphone"),
        Product(id: "p3", name: "AirPods Pro 3", price: 1899, category: "配件", icon: "airpodspro"),
        Product(id: "p4", name: "iPad Air M3", price: 6499, category: "平板", icon: "ipad"),
        Product(id: "p5", name: "Apple Watch Ultra 3", price: 5999, category: "手表", icon: "applewatch"),
        Product(id: "p6", name: "Studio Display", price: 11499, category: "显示器", icon: "display"),
        Product(id: "p7", name: "Magic Keyboard", price: 2499, category: "配件", icon: "keyboard"),
        Product(id: "p8", name: "HomePod mini", price: 749, category: "音箱", icon: "hifispeaker"),
    ]

    public static let categories = ["全部", "电脑", "手机", "平板", "配件", "手表", "显示器", "音箱"]
}

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

// MARK: - 模块注册

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

// MARK: - 商品列表视图

public struct ProductListView: View {
    public let category: String
    @State private var selectedCategory: String
    @Environment(\.navigator) private var navigator

    public init(category: String) {
        self.category = category
        _selectedCategory = State(initialValue: category)
    }

    private var filteredProducts: [Product] {
        if selectedCategory == "全部" {
            return ProductData.products
        }
        return ProductData.products.filter { $0.category == selectedCategory }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 分类筛选
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ProductData.categories, id: \.self) { cat in
                            Button {
                                selectedCategory = cat
                            } label: {
                                Text(cat)
                                    .font(.subheadline)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(selectedCategory == cat ? Color.blue : Color.secondary.opacity(0.15))
                                    .foregroundColor(selectedCategory == cat ? .white : .primary)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // 商品网格
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(filteredProducts) { product in
                        ProductCard(product: product) {
                            navigator.push(ProductRoutes.Detail(productID: product.id))
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("商品")
    }
}

// MARK: - 商品卡片

private struct ProductCard: View {
    let product: Product
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: product.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)

                Text(product.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                    .foregroundColor(.primary)

                HStack {
                    Text("¥\(Int(product.price))")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                    Spacer()
                    Text(product.category)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(4)
                }
            }
            .padding(8)
            .background(Color.primary.opacity(0.03))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }
}

// MARK: - 商品详情视图

public struct ProductDetailView: View {
    public let productID: String
    @Environment(\.navigator) private var navigator
    @State private var quantity = 1
    @State private var showAddedAlert = false

    private var product: Product {
        ProductData.products.first { $0.id == productID }
            ?? Product(id: productID, name: "Unknown", price: 0, category: "", icon: "questionmark")
    }

    public init(productID: String) {
        self.productID = productID
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 商品图片
                Image(systemName: product.icon)
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(
                        LinearGradient(colors: [.blue.opacity(0.1), .clear],
                                       startPoint: .top, endPoint: .bottom)
                    )

                VStack(alignment: .leading, spacing: 12) {
                    Text(product.name)
                        .font(.title2.bold())

                    HStack {
                        Text("¥\(Int(product.price))")
                            .font(.title.bold())
                            .foregroundColor(.red)
                        Spacer()
                        Label(product.category, systemImage: "tag")
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(8)
                    }

                    Divider()

                    // 数量选择
                    HStack {
                        Text("数量")
                        Spacer()
                        HStack(spacing: 16) {
                            Button { quantity = max(1, quantity - 1) } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                            }
                            Text("\(quantity)")
                                .font(.headline)
                                .frame(width: 30)
                            Button { quantity += 1 } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                        }
                    }

                    // 跨模块导航提示
                    VStack(alignment: .leading, spacing: 4) {
                        Label("跨模块导航演示", systemImage: "arrow.triangle.branch")
                            .font(.caption.bold())
                        Text("「加入购物车」将跨模块导航到 OrderModule 的购物车页面，并共享购物车状态")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
            }
        }
        .navigationTitle("商品详情")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    CartManager.shared.addItem(
                        id: product.id,
                        name: product.name,
                        price: product.price,
                        quantity: quantity
                    )
                    showAddedAlert = true
                } label: {
                    HStack {
                        Image(systemName: "cart.badge.plus")
                        Text("加入购物车  ¥\(Int(product.price * Double(quantity)))")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .alert("已加入购物车", isPresented: $showAddedAlert) {
                    Button("查看购物车") {
                        navigator.navigate(to: "order/cart")
                    }
                    Button("继续购物", role: .cancel) {}
                } message: {
                    Text("\(product.name) x\(quantity)")
                }
            }
        }
    }
}
