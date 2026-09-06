import SwiftUI
import AppBase

/// 商品列表视图（搜索 + 分类筛选 + 收藏）
public struct ProductListView: View {
    @Environment(AnyRouter.self) private var router
    @State private var viewModel: ProductListViewModel

    public init(category: String) {
        _viewModel = State(initialValue: ProductListViewModel(category: category))
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                searchBar
                categoryBar
                grid
            }
        }
        .id(filterState)
        .navigationTitle("商品")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.showFavoritesOnly.toggle()
                } label: {
                    Image(systemName: viewModel.showFavoritesOnly ? "heart.fill" : "heart")
                        .foregroundStyle(viewModel.showFavoritesOnly ? .red : .secondary)
                }
            }
        }
    }

    private var filterState: String {
        "\(viewModel.selectedCategory)|\(viewModel.showFavoritesOnly)"
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("搜索商品或分类", text: $viewModel.searchText)
                .autocorrectionDisabled()
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.categories, id: \.self) { cat in
                    Button {
                        viewModel.selectCategory(cat)
                    } label: {
                        Text(cat)
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(viewModel.selectedCategory == cat ? Color.blue : Color.secondary.opacity(0.15))
                            .foregroundColor(viewModel.selectedCategory == cat ? .white : .primary)
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var grid: some View {
        Group {
            if viewModel.filteredProducts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("没有找到相关商品")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(viewModel.filteredProducts) { product in
                        ProductCard(
                            product: product,
                            isFavorite: viewModel.isFavorite(product.id)
                        ) {
                            router.push(ProductRoutes.Detail(productID: product.id))
                        } onFavorite: {
                            viewModel.toggleFavorite(product.id)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - 商品卡片

private struct ProductCard: View {
    let product: Product
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: product.icon)
                        .font(.system(size: 36))
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(12)
                    Button(action: onFavorite) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.subheadline)
                            .foregroundStyle(isFavorite ? .red : .secondary)
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                }

                Text(product.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                    .foregroundColor(.primary)

                HStack {
                    Text("¥\(Int(product.price))")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                    Spacer()
                    Text(product.category)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(4)
                }
            }
            .padding(8)
            .background(Color.primary.opacity(0.03))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}
