import Foundation
import Observation
import AppBase
import OrderContracts

/// 订单仓库 - 内存态订单数据，负责下单、支付、状态流转
/// 未来可替换为网络 / 数据库实现
@Observable
public final class OrderRepository: @unchecked Sendable {
    public static let shared = OrderRepository()

    private var orders: [Order] = []
    private var nextID = 1

    private let lock = NSLock()

    private init() {
        seedDemoOrders()
    }

    // MARK: - 查询

    public func all() -> [Order] {
        lock.lock(); defer { lock.unlock() }
        return orders.sorted { $0.date > $1.date }
    }

    public func order(id: String) -> Order? {
        lock.lock(); defer { lock.unlock() }
        return orders.first { $0.id == id }
    }

    // MARK: - 下单（从购物车生成订单）

    /// 将购物车内容创建为订单，成功返回订单，随后清空购物车
    @discardableResult
    @MainActor
    public func placeOrder(cart: CartService) -> Order? {
        lock.lock(); defer { lock.unlock() }
        guard !cart.items.isEmpty else { return nil }
        let items = cart.items.map {
            OrderItem(id: $0.id, name: $0.name, price: $0.price, quantity: $0.quantity)
        }
        let id = "order\(nextID)"
        nextID += 1
        let order = Order(id: id, items: items, status: .pendingPayment, isPaid: false)
        orders.append(order)
        cart.clear()
        return order
    }

    /// 支付订单：待支付 -> 待发货
    @discardableResult
    public func pay(orderID: String) -> Order? {
        lock.lock(); defer { lock.unlock() }
        guard let idx = orders.firstIndex(where: { $0.id == orderID }),
              orders[idx].status == .pendingPayment else { return nil }
        orders[idx].status = .pendingShipment
        orders[idx] = Order(
            id: orders[idx].id,
            items: orders[idx].items,
            status: .pendingShipment,
            date: orders[idx].date,
            isPaid: true
        )
        return orders[idx]
    }

    /// 取消订单
    @discardableResult
    public func cancel(orderID: String) -> Order? {
        lock.lock(); defer { lock.unlock() }
        guard let idx = orders.firstIndex(where: { $0.id == orderID }),
              orders[idx].status != .delivered else { return nil }
        orders[idx].status = .cancelled
        return orders[idx]
    }

    /// 推进订单状态（演示物流流转）
    @discardableResult
    public func advance(orderID: String) -> Order? {
        lock.lock(); defer { lock.unlock() }
        guard let idx = orders.firstIndex(where: { $0.id == orderID }),
              let next = orders[idx].status.next else { return nil }
        orders[idx].status = next
        return orders[idx]
    }

    // MARK: - 演示数据

    private func seedDemoOrders() {
        orders = [
            Order(
                id: "order1",
                items: [OrderItem(id: "p1", name: "MacBook Pro 16\"", price: 19999, quantity: 1)],
                status: .delivered,
                date: Date(timeIntervalSinceNow: -86400 * 16),
                isPaid: true
            ),
            Order(
                id: "order2",
                items: [OrderItem(id: "p2", name: "iPhone 17 Pro", price: 8999, quantity: 2)],
                status: .shipping,
                date: Date(timeIntervalSinceNow: -86400 * 4),
                isPaid: true
            ),
            Order(
                id: "order3",
                items: [OrderItem(id: "p3", name: "AirPods Pro 3", price: 1899, quantity: 1)],
                status: .pendingPayment,
                date: Date(timeIntervalSinceNow: -86400 * 2),
                isPaid: false
            ),
        ]
        nextID = 4
    }
}
