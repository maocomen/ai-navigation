import SwiftUI
import AppBase
import ProductContracts

/// 订单详情视图（支付/取消/状态推进）
public struct OrderDetailView: View {
    @Environment(\.navigator) private var navigator
    @State private var viewModel: OrderDetailViewModel
    @State private var showMessage = false

    public init(orderID: String) {
        _viewModel = State(initialValue: OrderDetailViewModel(orderID: orderID))
    }

    public var body: some View {
        List {
            if let order = viewModel.order {
                infoSection(order)
                amountSection(order)
                itemSection(order)
                actionSection(order)
                trackingSection(order)
            } else {
                Text("订单不存在")
            }
        }
        .navigationTitle("订单详情")
        .alert("提示", isPresented: $showMessage) {
            Button("好", role: .cancel) {}
        } message: {
            Text(viewModel.message ?? "")
        }
    }

    private func infoSection(_ order: Order) -> some View {
        Section("订单信息") {
            LabeledContent("订单号", value: order.id.uppercased())
            LabeledContent("下单时间", value: order.date.formatted(date: .abbreviated, time: .shortened))
            LabeledContent("状态", value: order.status.rawValue)
            LabeledContent("支付状态", value: order.isPaid ? "已支付" : "未支付")
        }
    }

    private func itemSection(_ order: Order) -> some View {
        Section("商品 (\(order.totalCount)件)") {
            ForEach(order.items) { item in
                HStack {
                    Text(item.name)
                        .font(.subheadline)
                    Spacer()
                    Text("¥\(Int(item.price)) x \(item.quantity)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func amountSection(_ order: Order) -> some View {
        Section("金额") {
            LabeledContent("商品金额", value: "¥\(Int(order.totalPrice))")
            LabeledContent("运费", value: "¥0")
            LabeledContent("实付金额", value: "¥\(Int(order.totalPrice))")
                .foregroundColor(.red)
        }
    }

    @ViewBuilder
    private func actionSection(_ order: Order) -> some View {
        switch order.status {
        case .pendingPayment:
            Section("操作") {
                Button("立即支付") {
                    viewModel.pay()
                    showMessage = true
                }
                Button("取消订单", role: .destructive) {
                    viewModel.cancel()
                    showMessage = true
                }
            }
        case .pendingShipment, .shipping:
            Section("操作") {
                Button("模拟推进物流") {
                    viewModel.advance()
                    showMessage = true
                }
            }
        case .delivered:
            Section("操作") {
                Button("再次购买") {
                    navigator.navigate(to: ProductLinks.list)
                }
            }
        case .cancelled:
            EmptyView()
        }
    }

    @ViewBuilder
    private func trackingSection(_ order: Order) -> some View {
        if order.status == .shipping || order.status == .delivered {
            Section("物流追踪") {
                TimelineView {
                    trackingEvent("已签收", isActive: order.status == .delivered, order: order)
                    trackingEvent("配送中", isActive: order.status == .shipping, order: order)
                    trackingEvent("已发货", isActive: false, order: order)
                    trackingEvent("待发货", isActive: false, order: order)
                }
            }
        }
    }

    private func trackingEvent(_ title: String, isActive: Bool, order: Order) -> some View {
        EventView(title: title, date: order.date, isLatest: isActive)
    }
}

// MARK: - 辅助视图

private struct EventView: View {
    let title: String
    let date: Date
    let isLatest: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(isLatest ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: 10, height: 10)
                .padding(.top, 4)
            VStack(alignment: .leading) {
                Text(title)
                    .font(isLatest ? .subheadline.bold() : .subheadline)
                    .foregroundColor(isLatest ? .primary : .secondary)
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct TimelineView<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
    }
}
