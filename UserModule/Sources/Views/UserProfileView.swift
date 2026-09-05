import SwiftUI
import AppBase

/// 用户主页视图
public struct UserProfileView: View {
    @Environment(\.navigator) private var navigator
    @State private var viewModel: ProfileViewModel
    @State private var showSaved = false

    public init(userID: String) {
        _viewModel = State(initialValue: ProfileViewModel(userID: userID))
    }

    public var body: some View {
        List {
            basicInfoSection
            accountSection
            if viewModel.isCurrentUser {
                actionsSection
            }
        }
        .navigationTitle("个人中心")
        .alert("已保存", isPresented: $showSaved) {
            Button("好", role: .cancel) {}
        } message: {
            Text("资料更新成功")
        }
    }

    private var basicInfoSection: some View {
        Section("基本信息") {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 4) {
                    if viewModel.isEditing {
                        TextField("昵称", text: $viewModel.nickname)
                        TextField("签名", text: $viewModel.bio)
                    } else {
                        Text(viewModel.nickname.isEmpty ? viewModel.userID : viewModel.nickname)
                            .font(.headline)
                        Text(viewModel.bio.isEmpty ? "这个人很懒" : viewModel.bio)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var accountSection: some View {
        Section("账户信息") {
            LabeledContent("用户ID", value: viewModel.userID)
            LabeledContent("用户名", value: viewModel.user?.username ?? "-")
            LabeledContent("邮箱", value: viewModel.user?.email ?? "-")
            LabeledContent("注册时间", value: viewModel.user?.registerDate.formatted(date: .abbreviated, time: .omitted) ?? "-")
        }
    }

    @ViewBuilder
    private var actionsSection: some View {
        Section {
            if viewModel.isEditing {
                Button("保存资料") {
                    viewModel.save()
                    showSaved = true
                }
                Button("取消", role: .cancel) { viewModel.isEditing = false }
            } else {
                Button("编辑资料") { viewModel.beginEditing() }
            }
            Button("查看订单") { navigator.navigate(to: "order/list") }
            Button("浏览商品") { navigator.navigate(to: "product/list") }
            Button("账号设置") { navigator.push(UserRoutes.Settings()) }
        }

        Section {
            Button("退出登录", role: .destructive) {
                viewModel.logout()
                navigator.popToRoot()
            }
        }
    }
}
