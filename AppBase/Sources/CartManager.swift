import Foundation

/// 购物车管理器 - 跨模块共享状态示例
public final class CartManager: ObservableObject, @unchecked Sendable {
    public static let shared = CartManager()

    public struct CartItem: Identifiable, Sendable {
        public let id: String
        public let name: String
        public let price: Double
        public let quantity: Int

        public init(id: String, name: String, price: Double, quantity: Int) {
            self.id = id
            self.name = name
            self.price = price
            self.quantity = quantity
        }

        public var subtotal: Double { price * Double(quantity) }
    }

    @Published public var items: [CartItem] = []

    public var totalCount: Int { items.reduce(0) { $0 + $1.quantity } }
    public var totalPrice: Double { items.reduce(0) { $0 + $1.subtotal } }

    private init() {}

    public func addItem(id: String, name: String, price: Double, quantity: Int = 1) {
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
