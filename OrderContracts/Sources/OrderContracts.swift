import Foundation

/// 订单域对外链接常量（单一真相源）
///
/// 所有跨模块跳转（跳购物车/订单列表/结算等）均引用此处常量，
/// 换链接只改这一处，编译期保证一致。
public enum OrderLinks {
    public static let cart = "order/cart"
    public static let list = "order/list"
    public static let detail = "order/detail"
    public static let checkout = "order/checkout"
}

/// 购物车条目（值类型模型）
public struct CartItem: Identifiable, Equatable, Sendable {
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

/// 购物车服务协议 - 跨模块共享的购物车状态抽象
///
/// 本协议从 ServiceContracts 迁入 OrderContracts，
/// 因购物车属于订单域（OrderDomain）。
/// 拥有方（OrderModule）实现此协议，消费方（ProductModule）按协议操作。
@MainActor
public protocol CartService: AnyObject {
    var items: [CartItem] { get }
    var totalCount: Int { get }
    var totalPrice: Double { get }
    func addItem(id: String, name: String, price: Double, quantity: Int)
    func removeItem(id: String)
    func clear()
}

public extension CartService {
    func addItem(id: String, name: String, price: Double, quantity: Int = 1) {
        addItem(id: id, name: name, price: price, quantity: quantity)
    }
}

/// 空购物车服务 - 兜底实现（未注册服务时使用，行为同空购物车）
@MainActor
public final class EmptyCartService: CartService, @unchecked Sendable {
    public init() {}
    public var items: [CartItem] { [] }
    public var totalCount: Int { 0 }
    public var totalPrice: Double { 0 }
    public func addItem(id: String, name: String, price: Double, quantity: Int) {}
    public func removeItem(id: String) {}
    public func clear() {}
}
