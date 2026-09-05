import SwiftUI
import AppBase
import OrderContracts
import ProductContracts

/// 购物车视图
public struct CartView: View {
    @Environment(\.navigator) private var navigator
    @State private var viewModel = CartViewModel()

    public init() {}

    public var body: some View {
        Group {
            if viewModel.isEmpty {
                emptyState
            } else {
                cartList
            }
        }
        .navigationTitle("购物车")
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "cart")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("购物车是空的")
                .font(.title3)
            Text("去商品页添加一些商品吧")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("浏览商品") {
                navigator.navigate(to: ProductLinks.list)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var cartList: some View {
        List {
            Section {
                ForEach(viewModel.items) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.headline)
                            Text("¥\(Int(item.price)) x \(item.quantity)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("¥\(Int(item.subtotal))")
                                .font(.headline)
                                .foregroundColor(.red)
                            Button("移除") {
                                viewModel.removeItem(id: item.id)
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                }
            } header: {
                Text("购物车商品 (\(viewModel.totalCount)件)")
            }

            Section {
                HStack {
                    Text("总计")
                        .font(.headline)
                    Spacer()
                    Text("¥\(Int(viewModel.totalPrice))")
                        .font(.title2.bold())
                        .foregroundColor(.red)
                }
                Button {
                    navigator.push(OrderRoutes.Checkout())
                } label: {
                    Text("去结算")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("清空") { viewModel.clear() }
                    .foregroundColor(.red)
            }
        }
    }
}
