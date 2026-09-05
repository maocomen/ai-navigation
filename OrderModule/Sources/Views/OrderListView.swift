import SwiftUI
import AppBase

/// 订单列表视图
public struct OrderListView: View {
    @Environment(Router.self) private var router
    @State private var viewModel = OrderListViewModel()

    public init() {}

    public var body: some View {
        List {
            ForEach(viewModel.orders) { order in
                Button {
                    router.push(OrderRoutes.Detail(orderID: order.id))
                } label: {
                    OrderRow(order: order)
                }
            }
        }
        .navigationTitle("我的订单")
    }
}

// MARK: - 订单行

private struct OrderRow: View {
    let order: Order

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(order.productSummary)
                    .font(.headline)
                    .lineLimit(1)
                Text(order.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("¥\(Int(order.totalPrice))")
                    .font(.subheadline.bold())
                    .foregroundColor(.red)
                Text(order.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor(order.status))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }

    private func statusColor(_ status: OrderStatus) -> Color {
        switch status {
        case .delivered: return .green
        case .shipping: return .orange
        case .pendingShipment: return .blue
        case .pendingPayment: return .purple
        case .cancelled: return .gray
        }
    }
}
