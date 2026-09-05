import Foundation
import SwiftUI
import AppBase
import OrderContracts

// MARK: - 购物车 ViewModel

@Observable
@MainActor
public final class CartViewModel {
    public let cart: CartServiceImpl
    private let orderRepository: OrderRepository

    public init(cart: CartServiceImpl? = nil, orderRepository: OrderRepository = .shared) {
        self.cart = cart ?? CartServiceImpl.shared
        self.orderRepository = orderRepository
    }

    public var items: [CartItem] { cart.items }
    public var isEmpty: Bool { cart.items.isEmpty }
    public var totalCount: Int { cart.totalCount }
    public var totalPrice: Double { cart.totalPrice }

    public func removeItem(id: String) { cart.removeItem(id: id) }
    public func clear() { cart.clear() }

    /// 下单：生成订单并返回
    @discardableResult
    public func placeOrder() -> Order? {
        orderRepository.placeOrder(cart: cart)
    }
}

// MARK: - 订单列表 ViewModel

@Observable
@MainActor
public final class OrderListViewModel {
    private let repository: OrderRepository

    public init(repository: OrderRepository = .shared) {
        self.repository = repository
    }

    public var orders: [Order] { repository.all() }

    public func allOrders() -> [Order] { repository.all() }
}

// MARK: - 订单详情 ViewModel（含支付/取消/状态推进）

@Observable
@MainActor
public final class OrderDetailViewModel {
    public let orderID: String
    public var message: String?

    private let repository: OrderRepository

    public init(orderID: String, repository: OrderRepository = .shared) {
        self.orderID = orderID
        self.repository = repository
    }

    public var order: Order? {
        repository.order(id: orderID)
    }

    public func pay() {
        guard let o = repository.pay(orderID: orderID) else { return }
        message = "支付成功，订单进入待发货"
        _ = o
    }

    public func cancel() {
        guard let _ = repository.cancel(orderID: orderID) else { return }
        message = "订单已取消"
    }

    public func advance() {
        guard let o = repository.advance(orderID: orderID) else { return }
        message = "状态已更新为「\(o.status.rawValue)」"
    }
}

// MARK: - 结算 ViewModel（下单 + 支付）

@Observable
@MainActor
public final class CheckoutViewModel {
    public var isPaying = false
    public var placedOrder: Order?

    public let cart: CartServiceImpl
    private let orderRepository: OrderRepository

    public init(cart: CartServiceImpl? = nil, orderRepository: OrderRepository = .shared) {
        self.cart = cart ?? CartServiceImpl.shared
        self.orderRepository = orderRepository
    }

    public var totalCount: Int { cart.totalCount }
    public var totalPrice: Double { cart.totalPrice }

    /// 提交订单
    public func submitOrder() {
        placedOrder = orderRepository.placeOrder(cart: cart)
    }

    /// 支付当前已下订单
    public func pay() {
        isPaying = true
        if let order = placedOrder {
            let _ = orderRepository.pay(orderID: order.id)
        }
        isPaying = false
    }
}
