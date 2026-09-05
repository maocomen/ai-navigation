import Foundation

/// 订单状态枚举
public enum OrderStatus: String, Codable, CaseIterable, Sendable {
    case pendingPayment = "待支付"
    case pendingShipment = "待发货"
    case shipping = "配送中"
    case delivered = "已送达"
    case cancelled = "已取消"

    /// 状态流转：下一个可到达的状态
    public var next: OrderStatus? {
        switch self {
        case .pendingPayment: return .pendingShipment   // 支付后 -> 待发货
        case .pendingShipment: return .shipping         // 发货 -> 配送中
        case .shipping: return .delivered               // 签收 -> 已送达
        case .delivered: return nil
        case .cancelled: return nil
        }
    }

    public var color: String { rawValue } // 占位，实际颜色在 View 层映射
}

/// 订单条目
public struct OrderItem: Identifiable, Equatable, Sendable {
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

/// 订单模型
public struct Order: Identifiable, Equatable, Sendable {
    public let id: String
    public var items: [OrderItem]
    public var status: OrderStatus
    public let date: Date
    public let isPaid: Bool

    public init(
        id: String,
        items: [OrderItem],
        status: OrderStatus,
        date: Date = Date(),
        isPaid: Bool = false
    ) {
        self.id = id
        self.items = items
        self.status = status
        self.date = date
        self.isPaid = isPaid
    }

    public var totalPrice: Double {
        items.reduce(0) { $0 + $1.subtotal }
    }

    public var totalCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    public var productSummary: String {
        items.map { $0.name }.joined(separator: "、")
    }
}
