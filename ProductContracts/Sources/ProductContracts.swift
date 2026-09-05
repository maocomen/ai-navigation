import Foundation

/// 商品域对外链接常量（单一真相源）
///
/// 所有跨模块跳转（跳商品列表/商品详情等）均引用此处常量。
public enum ProductLinks {
    public static let list = "product/list"
    public static let detail = "product/detail"
}
