import SwiftUI
import AppBase

// MARK: - 订单数据模型

public struct Order: Identifiable, Sendable {
    public let id: String
    public let productNames: String
    public let totalPrice: Double
    public let status: String
    public let date: String

    public init(id: String, productNames: String, totalPrice: Double, status: String, date: String) {
        self.id = id
        self.productNames = productNames
        self.totalPrice = totalPrice
        self.status = status
        self.date = date
    }
}

public struct OrderData {
    public static let orders: [Order] = [
        Order(id: "o1", productNames: "MacBook Pro 16\"", totalPrice: 19999, status: "已送达", date: "2026-08-20"),
        Order(id: "o2", productNames: "iPhone 17 Pro x2", totalPrice: 17998, status: "配送中", date: "2026-09-01"),
        Order(id: "o3", productNames: "AirPods Pro 3", totalPrice: 1899, status: "待发货", date: "2026-09-03"),
    ]
}

// MARK: - 路由定义

public enum OrderRoutes {

    public struct Cart: RouteType {
        public static var path: String { "order/cart" }
        public init() {}
        public static func == (lhs: Cart, rhs: Cart) -> Bool { true }
        public func hash(into hasher: inout Hasher) { hasher.combine("cart") }
        @MainActor public func makeView() -> AnyView { AnyView(CartView()) }
    }

    public struct List: RouteType {
        public static var path: String { "order/list" }
        public init() {}
        public static func == (lhs: List, rhs: List) -> Bool { true }
        public func hash(into hasher: inout Hasher) { hasher.combine("orderlist") }
        @MainActor public func makeView() -> AnyView { AnyView(OrderListView()) }
    }

    public struct Detail: RouteType {
        public static var path: String { "order/detail" }
        public let orderID: String
        public init(orderID: String) { self.orderID = orderID }
        public static func == (lhs: Detail, rhs: Detail) -> Bool { lhs.orderID == rhs.orderID }
        public func hash(into hasher: inout Hasher) { hasher.combine(orderID) }
        @MainActor public func makeView() -> AnyView { AnyView(OrderDetailView(orderID: orderID)) }
    }
}

// MARK: - 模块注册

public final class OrderModule: ModuleProtocol {
    public var moduleID: String { "com.app.order" }
    public var moduleName: String { "OrderModule" }
    public init() {}

    public func registerRoutes(in registry: ModuleRegistry) {
        registry.addRoute(OrderRoutes.Cart())
        registry.addRoute(OrderRoutes.List())
        registry.addRouteFactory("order/detail") { params in
            guard let orderID = params["orderID"] as? String else { return nil }
            return OrderRoutes.Detail(orderID: orderID)
        }
    }

    public func initializeResources() {}

    public static func initialize() {
        ModuleRegistry.shared.registerModule(OrderModule())
    }
}

// MARK: - 购物车视图

public struct CartView: View {
    @ObservedObject private var cart = CartManager.shared
    @Environment(\.navigator) private var navigator

    public init() {}

    public var body: some View {
        Group {
            if cart.items.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "cart")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                    Text("购物车是空的")
                        .font(.title3)
                    Text("去商品页添加一些商品吧")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("浏览商品") {
                        navigator.navigate(to: "product/list")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    Section {
                        ForEach(cart.items) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .font(.headline)
                                    Text("¥\(Int(item.price)) x \(item.quantity)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("¥\(Int(item.subtotal))")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                    Button("移除") {
                                        cart.removeItem(id: item.id)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.red)
                                }
                            }
                        }
                    } header: {
                        Text("购物车商品 (\(cart.totalCount)件)")
                    }

                    Section {
                        HStack {
                            Text("总计")
                                .font(.headline)
                            Spacer()
                            Text("¥\(Int(cart.totalPrice))")
                                .font(.title2.bold())
                                .foregroundColor(.red)
                        }
                        Button("模拟下单") {
                            cart.clear()
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .navigationTitle("购物车")
        .toolbar {
            if !cart.items.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button("清空") { cart.clear() }
                        .foregroundColor(.red)
                }
            }
        }
    }
}

// MARK: - 订单列表视图

public struct OrderListView: View {
    @Environment(\.navigator) private var navigator

    public init() {}

    public var body: some View {
        List {
            ForEach(OrderData.orders) { order in
                Button {
                    navigator.push(OrderRoutes.Detail(orderID: order.id))
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(order.productNames)
                                .font(.headline)
                            Text(order.date)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("¥\(Int(order.totalPrice))")
                                .font(.subheadline.bold())
                                .foregroundColor(.red)
                            Text(order.status)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(statusColor(order.status))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("我的订单")
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "已送达": return .green
        case "配送中": return .orange
        case "待发货": return .blue
        default: return .gray
        }
    }
}

// MARK: - 订单详情视图

public struct OrderDetailView: View {
    public let orderID: String

    private var order: Order {
        OrderData.orders.first { $0.id == orderID }
            ?? Order(id: orderID, productNames: "Unknown", totalPrice: 0, status: "未知", date: "")
    }

    public init(orderID: String) {
        self.orderID = orderID
    }

    public var body: some View {
        List {
            Section("订单信息") {
                LabeledContent("订单号", value: order.id.uppercased())
                LabeledContent("商品", value: order.productNames)
                LabeledContent("下单时间", value: order.date)
                LabeledContent("状态", value: order.status)
            }

            Section("金额") {
                LabeledContent("商品金额", value: "¥\(Int(order.totalPrice))")
                LabeledContent("运费", value: "¥0")
                LabeledContent("优惠", value: "-¥0")
                LabeledContent("实付金额", value: "¥\(Int(order.totalPrice))")
                    .foregroundColor(.red)
            }

            Section("物流追踪") {
                TimelineView {
                    EventView(title: "已签收", date: order.date, isLatest: true)
                    EventView(title: "配送中", date: order.date, isLatest: false)
                    EventView(title: "已发货", date: order.date, isLatest: false)
                    EventView(title: "待发货", date: order.date, isLatest: false)
                }
            }
        }
        .navigationTitle("订单详情")
    }
}

// MARK: - 辅助视图

private struct EventView: View {
    let title: String
    let date: String
    let isLatest: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(isLatest ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: 10, height: 10)
                .padding(.top, 4)
            VStack(alignment: .leading) {
                Text(title)
                    .font(isLatest ? .subheadline.bold() : .subheadline)
                    .foregroundColor(isLatest ? .primary : .secondary)
                Text(date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct TimelineView<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
    }
}
