import Foundation

/// 商品模型
public struct Product: Identifiable, Equatable, Sendable {
    public let id: String
    public var name: String
    public var price: Double
    public var category: String
    public var icon: String
    public var detail: String

    public init(
        id: String,
        name: String,
        price: Double,
        category: String,
        icon: String,
        detail: String = ""
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.category = category
        self.icon = icon
        self.detail = detail
    }
}
