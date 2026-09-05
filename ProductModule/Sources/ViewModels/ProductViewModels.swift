import Foundation
import SwiftUI
import AppBase
import OrderContracts

// MARK: - 商品列表 ViewModel（含搜索/筛选/收藏）

@Observable
@MainActor
public final class ProductListViewModel {
    public var searchText = ""
    public var selectedCategory: String
    public var showFavoritesOnly = false

    private let repository: ProductRepository

    public init(category: String = "全部", repository: ProductRepository = .shared) {
        self.selectedCategory = category
        self.repository = repository
    }

    public var categories: [String] { ProductRepository.categories }

    public var filteredProducts: [Product] {
        var list = repository.all()
        if showFavoritesOnly {
            list = list.filter { repository.isFavorite($0.id) }
        }
        if selectedCategory != "全部" {
            list = list.filter { $0.category == selectedCategory }
        }
        if !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            let keyword = searchText.trimmingCharacters(in: .whitespaces).lowercased()
            list = list.filter {
                $0.name.lowercased().contains(keyword)
                    || $0.category.lowercased().contains(keyword)
            }
        }
        return list
    }

    public func selectCategory(_ category: String) {
        selectedCategory = category
    }

    public func toggleFavorite(_ id: String) {
        repository.toggleFavorite(id)
    }

    public func isFavorite(_ id: String) -> Bool {
        repository.isFavorite(id)
    }
}

// MARK: - 商品详情 ViewModel（含数量与加购）

@Observable
@MainActor
public final class ProductDetailViewModel {
    public var quantity = 1

    public let product: Product
    private let repository: ProductRepository
    private let cart: CartService

    public init(productID: String, repository: ProductRepository = .shared, cart: CartService? = nil) {
        self.repository = repository
        self.cart = cart ?? ServiceContainer.shared.resolve(CartService.self) ?? EmptyCartService()
        self.product = repository.product(id: productID)
            ?? Product(id: productID, name: "Unknown", price: 0, category: "", icon: "questionmark")
    }

    public var isFavorite: Bool {
        repository.isFavorite(product.id)
    }

    public var totalPrice: Double {
        product.price * Double(quantity)
    }

    public func increase() { quantity += 1 }
    public func decrease() { quantity = max(1, quantity - 1) }
    public func toggleFavorite() { repository.toggleFavorite(product.id) }

    public func addToCart() {
        cart.addItem(id: product.id, name: product.name, price: product.price, quantity: quantity)
    }
}
