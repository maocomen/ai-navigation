import SwiftUI
import AppBase

/// 商品详情视图（收藏 + 数量选择 + 加购）
public struct ProductDetailView: View {
    @Environment(\.navigator) private var navigator
    @State private var viewModel: ProductDetailViewModel
    @State private var showAddedAlert = false

    public init(productID: String) {
        _viewModel = State(initialValue: ProductDetailViewModel(productID: productID))
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroImage
                infoSection
            }
        }
        .navigationTitle("商品详情")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.toggleFavorite()
                } label: {
                    Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(viewModel.isFavorite ? .red : .secondary)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            addToCartBar
        }
        .alert("已加入购物车", isPresented: $showAddedAlert) {
            Button("查看购物车") { navigator.navigate(to: "order/cart") }
            Button("继续购物", role: .cancel) {}
        } message: {
            Text("\(viewModel.product.name) x\(viewModel.quantity)")
        }
    }

    private var heroImage: some View {
        Image(systemName: viewModel.product.icon)
            .font(.system(size: 80))
            .foregroundStyle(.blue)
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(
                LinearGradient(colors: [.blue.opacity(0.1), .clear],
                               startPoint: .top, endPoint: .bottom)
            )
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.product.name)
                .font(.title2.bold())

            HStack {
                Text("¥\(Int(viewModel.product.price))")
                    .font(.title.bold())
                    .foregroundColor(.red)
                Spacer()
                Label(viewModel.product.category, systemImage: "tag")
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(8)
            }

            if !viewModel.product.detail.isEmpty {
                Text(viewModel.product.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }

            Divider()

            HStack {
                Text("数量")
                Spacer()
                HStack(spacing: 16) {
                    Button { viewModel.decrease() } label: {
                        Image(systemName: "minus.circle.fill").font(.title2)
                    }
                    Text("\(viewModel.quantity)")
                        .font(.headline)
                        .frame(width: 30)
                    Button { viewModel.increase() } label: {
                        Image(systemName: "plus.circle.fill").font(.title2)
                    }
                }
            }
        }
        .padding()
    }

    private var addToCartBar: some View {
        VStack {
            Divider()
            Button {
                viewModel.addToCart()
                showAddedAlert = true
            } label: {
                HStack {
                    Image(systemName: "cart.badge.plus")
                    Text("加入购物车  ¥\(Int(viewModel.totalPrice))")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(.background)
    }
}
