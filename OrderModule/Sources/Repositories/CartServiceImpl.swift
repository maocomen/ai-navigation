import Foundation
import SwiftUI
import AppBase
import OrderContracts

/// 购物车服务实现 - 内存态购物车（订单域概念，实现 `CartService` 协议）
///
/// 采用 `@Observable` 宏，供订单域内 View/ViewModel 实时观察。
/// 在模块初始化时注册到 `ServiceContainer`，对外暴露为 `CartService` 协议，
/// 使 ProductModule 等消费方无需依赖具体实现。
@Observable
@MainActor
public final class CartServiceImpl: CartService {
    public static let shared = CartServiceImpl()

    public private(set) var items: [CartItem] = []

    public init() {}

    // MARK: - CartService

    public var totalCount: Int { items.reduce(0) { $0 + $1.quantity } }
    public var totalPrice: Double { items.reduce(0) { $0 + $1.subtotal } }

    public func addItem(id: String, name: String, price: Double, quantity: Int) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            let existing = items[index]
            items[index] = CartItem(id: id, name: name, price: price, quantity: existing.quantity + quantity)
        } else {
            items.append(CartItem(id: id, name: name, price: price, quantity: quantity))
        }
    }

    public func removeItem(id: String) {
        items.removeAll { $0.id == id }
    }

    public func clear() {
        items.removeAll()
    }
}
