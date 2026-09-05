import SwiftUI
import AppBase

/// 注册视图
public struct RegisterView: View {
    @Environment(Router.self) private var router
    @State private var viewModel = RegisterViewModel()
    @State private var showSuccess = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                    .padding(.top, 24)

                form
                message
                submitButton
            }
        }
        .navigationTitle("注册")
        .alert("注册成功", isPresented: $showSuccess) {
            Button("开始使用") { router.pop() }
        } message: {
            Text("账号 \(viewModel.username) 已创建")
        }
    }

    private var form: some View {
        VStack(spacing: 14) {
            TextField("用户名", text: $viewModel.username)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
            TextField("邮箱", text: $viewModel.email)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
            SecureField("密码（至少 6 位）", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
            SecureField("确认密码", text: $viewModel.confirmPassword)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var message: some View {
        if let error = viewModel.errorMessage {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
                .padding(.horizontal)
        }
    }

    private var submitButton: some View {
        Button {
            Task {
                if await viewModel.submit() != nil {
                    showSuccess = true
                }
            }
        } label: {
            Text("注册并登录")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canSubmit ? Color.green : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .disabled(!viewModel.canSubmit)
        .padding(.horizontal)
    }
}
