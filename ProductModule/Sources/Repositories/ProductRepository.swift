import Foundation

/// 商品仓库 - 内存态商品数据，支持分类/搜索/收藏
/// 未来可替换为网络 / 数据库实现
public final class ProductRepository: @unchecked Sendable {
    public static let shared = ProductRepository()

    private(set) var products: [Product]
    private var favoriteIDs: Set<String> = []

    private let lock = NSLock()

    private init() {
        products = [
            Product(id: "p1", name: "MacBook Pro 16\"", price: 19999, category: "电脑", icon: "laptopcomputer", detail: "M4 Pro 芯片，16 英寸 Liquid Retina XDR 显示屏"),
            Product(id: "p2", name: "iPhone 17 Pro", price: 8999, category: "手机", icon: "iphone", detail: "A19 Pro 芯片，5x 潜望式长焦镜头"),
            Product(id: "p3", name: "AirPods Pro 3", price: 1899, category: "配件", icon: "airpodspro", detail: "H3 芯片，自适应降噪"),
            Product(id: "p4", name: "iPad Air M3", price: 6499, category: "平板", icon: "ipad", detail: "13 英寸，M3 芯片，支持 Apple Pencil Pro"),
            Product(id: "p5", name: "Apple Watch Ultra 3", price: 5999, category: "手表", icon: "applewatch", detail: "钛金属表壳，双频 GPS"),
            Product(id: "p6", name: "Studio Display", price: 11499, category: "显示器", icon: "display", detail: "27 英寸 5K Retina 显示屏"),
            Product(id: "p7", name: "Magic Keyboard", price: 2499, category: "配件", icon: "keyboard", detail: "带触控 ID 的背光妙控键盘"),
            Product(id: "p8", name: "HomePod mini", price: 749, category: "音箱", icon: "hifispeaker", detail: "360° 环绕声场，Siri 语音助手"),
        ]
    }

    public static let categories = ["全部", "电脑", "手机", "平板", "配件", "手表", "显示器", "音箱"]

    // MARK: - 查询

    public func product(id: String) -> Product? {
        lock.lock(); defer { lock.unlock() }
        return products.first { $0.id == id }
    }

    public func all() -> [Product] {
        lock.lock(); defer { lock.unlock() }
        return products
    }

    // MARK: - 收藏

    public func isFavorite(_ id: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        return favoriteIDs.contains(id)
    }

    @discardableResult
    public func toggleFavorite(_ id: String) -> Bool {
        lock.lock(); defer { lock.unlock() }
        if favoriteIDs.contains(id) {
            favoriteIDs.remove(id)
            return false
        } else {
            favoriteIDs.insert(id)
            return true
        }
    }

    public func favorites() -> [Product] {
        lock.lock(); defer { lock.unlock() }
        return products.filter { favoriteIDs.contains($0.id) }
    }
}
