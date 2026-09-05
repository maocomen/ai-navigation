import SwiftUI
import AppBase

/// 结算视图（下单 + 支付）
public struct CheckoutView: View {
    @Environment(Router.self) private var router
    @State private var viewModel = CheckoutViewModel()
    @State private var showPaySuccess = false

    public init() {}

    public var body: some View {
        List {
            if let order = viewModel.placedOrder {
                orderSummary(order)
                paySection(order)
            } else {
                checkoutSummary
                submitSection
            }
        }
        .navigationTitle("确认订单")
        .alert("支付成功", isPresented: $showPaySuccess) {
            Button("查看订单") { router.popToRoot() }
        } message: {
            Text("订单已进入待发货状态")
        }
    }

    private var checkoutSummary: some View {
        Section("订单摘要") {
            HStack {
                Text("商品件数")
                Spacer()
                Text("\(viewModel.totalCount) 件")
            }
            HStack {
                Text("合计金额")
                Spacer()
                Text("¥\(Int(viewModel.totalPrice))")
                    .foregroundColor(.red)
                    .font(.headline)
            }
        }
    }

    private var submitSection: some View {
        Section {
            Button {
                viewModel.submitOrder()
            } label: {
                Text("提交订单  ¥\(Int(viewModel.totalPrice))")
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .disabled(viewModel.totalCount == 0)
        }
    }

    private func orderSummary(_ order: Order) -> some View {
        Section("订单已提交") {
            LabeledContent("订单号", value: order.id.uppercased())
            LabeledContent("商品", value: order.productSummary)
            LabeledContent("金额", value: "¥\(Int(order.totalPrice))")
            LabeledContent("状态", value: order.status.rawValue)
        }
    }

    private func paySection(_ order: Order) -> some View {
        Section("支付") {
            HStack {
                Label("模拟支付（Apple Pay 风格）", systemImage: "apple.logo")
                Spacer()
            }
            Button {
                viewModel.pay()
                showPaySuccess = true
            } label: {
                Text("立即支付  ¥\(Int(order.totalPrice))")
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(8)
            }
            Button("取消订单", role: .destructive) {
                router.pop()
            }
        }
    }
}
