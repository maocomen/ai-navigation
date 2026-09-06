import SwiftUI
import AppBase
import OrderContracts
import ProductContracts

/// 订单详情视图（支付/取消/状态推进）
public struct OrderDetailView: View {
    @Environment(AnyRouter.self) private var router
    @State private var viewModel: OrderDetailViewModel
    @State private var showMessage = false
    @State private var showCancelConfirm = false
    @State private var showRefundSheet = false

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
                supportSection(order)
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
        .alert("确认取消订单", isPresented: $showCancelConfirm) {
            Button("暂不取消", role: .cancel) {}
            Button("确认取消", role: .destructive) {
                viewModel.cancel()
                showMessage = true
            }
        } message: {
            Text("订单取消后无法恢复，确定要取消吗？")
        }
        .sheet(isPresented: $showRefundSheet) {
            RefundSheet(order: viewModel.order) { reason, detail in
                viewModel.submitRefund(reason: reason, detail: detail)
                showMessage = true
            }
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
                    showCancelConfirm = true
                }
            }
        case .pendingShipment:
            Section("操作") {
                Button("模拟推进物流") {
                    viewModel.advance()
                    showMessage = true
                }
                Button("取消订单", role: .destructive) {
                    showCancelConfirm = true
                }
            }
        case .shipped, .shipping:
            Section("操作") {
                Button("模拟推进物流") {
                    viewModel.advance()
                    showMessage = true
                }
            }
        case .delivered:
            Section("操作") {
                Button("再次购买") {
                    router.navigate(to: ProductLinks.list)
                }
            }
        case .cancelled:
            Section("操作") {
                Button("再来一单") {
                    viewModel.reorder()
                    router.navigate(to: OrderLinks.checkout)
                }
            }
        }
    }

    @ViewBuilder
    private func supportSection(_ order: Order) -> some View {
        if order.status != .cancelled && order.status != .delivered {
            Section("帮助") {
                Button {
                    showMessage = true
                    viewModel.message = "客服热线：400-888-8888\n工作时间：9:00-21:00"
                } label: {
                    Label("联系客服", systemImage: "phone.fill")
                }
                Button {
                    showRefundSheet = true
                } label: {
                    Label("退款/售后", systemImage: "arrow.uturn.backward")
                }
            }
        }
    }

    @ViewBuilder
    private func trackingSection(_ order: Order) -> some View {
        if order.status == .pendingShipment || order.status == .shipped || order.status == .shipping || order.status == .delivered {
            Section("物流追踪") {
                TimelineView {
                    trackingEvent("已签收", isActive: order.status == .delivered, order: order)
                    trackingEvent("配送中", isActive: order.status == .shipping || order.status == .delivered, order: order)
                    trackingEvent("已发货", isActive: order.status == .shipped || order.status == .shipping || order.status == .delivered, order: order)
                    trackingEvent("待发货", isActive: order.status == .pendingShipment || order.status == .shipped || order.status == .shipping || order.status == .delivered, order: order)
                }
            }
        }
    }

    private func trackingEvent(_ title: String, isActive: Bool, order: Order) -> some View {
        EventView(title: title, date: order.date, isLatest: isActive)
    }
}

// MARK: - 退款/售后 Sheet

private struct RefundSheet: View {
    let order: Order?
    let onSubmit: (RefundReason, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: RefundReason = .notNeeded
    @State private var detail = ""
    @State private var showConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section("退款类型") {
                    ForEach(RefundType.allCases) { type in
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundColor(type == .refund ? .red : .orange)
                                .frame(width: 24)
                            VStack(alignment: .leading) {
                                Text(type.title)
                                    .font(.subheadline)
                                Text(type.desc)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                }

                Section("退款原因") {
                    Picker("选择原因", selection: $selectedReason) {
                        ForEach(RefundReason.allCases) { reason in
                            Text(reason.title).tag(reason)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section("补充说明（选填）") {
                    TextEditor(text: $detail)
                        .frame(minHeight: 80)
                        .overlay(alignment: .topLeading) {
                            if detail.isEmpty {
                                Text("请描述您遇到的问题...")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                        }
                }

                Section {
                    Button("提交申请") {
                        showConfirm = true
                    }
                }
            }
            .navigationTitle("退款/售后")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .alert("确认提交", isPresented: $showConfirm) {
                Button("暂不提交", role: .cancel) {}
                Button("确认提交") {
                    onSubmit(selectedReason, detail)
                    dismiss()
                }
            } message: {
                Text("提交后客服将在 1-2 个工作日内处理您的申请，确定提交吗？")
            }
        }
    }
}

// MARK: - 退款类型

private enum RefundType: String, CaseIterable, Identifiable {
    case refund
    case exchange
    case repair

    var id: String { rawValue }

    var title: String {
        switch self {
        case .refund: return "仅退款"
        case .exchange: return "换货"
        case .repair: return "维修"
        }
    }

    var desc: String {
        switch self {
        case .refund: return "未收到货或无需退货，直接退款"
        case .exchange: return "收到商品有质量问题，申请换货"
        case .repair: return "商品在保修期内，申请维修"
        }
    }

    var icon: String {
        switch self {
        case .refund: return "yensign.circle"
        case .exchange: return "arrow.triangle.2.circlepath"
        case .repair: return "wrench.and.screwdriver"
        }
    }
}

// MARK: - 退款原因

public enum RefundReason: String, CaseIterable, Identifiable {
    case notNeeded = "不想要了"
    case wrongItem = "发错货"
    case defective = "商品有质量问题"
    case damaged = "运输途中损坏"
    case notAsDescribed = "与描述不符"
    case counterfeit = "假货/仿冒品"

    public var id: String { rawValue }
    public var title: String { rawValue }
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
