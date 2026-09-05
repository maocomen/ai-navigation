import SwiftUI
import AppBase

/// 登录视图
public struct LoginView: View {
    @Environment(Router.self) private var router
    @State private var viewModel = LoginViewModel()
    @State private var showWelcome = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                form
                loginButton
                registerLink
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }
            }
        }
        .navigationTitle("登录")
        .alert("登录成功", isPresented: $showWelcome) {
            Button("确定") { router.pop() }
        } message: {
            Text("欢迎回来，\(viewModel.username)！")
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            Text("用户登录")
                .font(.largeTitle.bold())
            Text("登录后可访问个人中心和订单")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 32)
    }

    private var form: some View {
        VStack(spacing: 16) {
            TextField("用户名", text: $viewModel.username)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
            SecureField("密码", text: $viewModel.password)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.horizontal)
    }

    private var loginButton: some View {
        Button {
            Task {
                if await viewModel.submit() {
                    showWelcome = true
                }
            }
        } label: {
            Group {
                if viewModel.isSubmitting {
                    ProgressView()
                } else {
                    Text("登录")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.canSubmit ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!viewModel.canSubmit)
        .padding(.horizontal)
    }

    private var registerLink: some View {
        Button("没有账号？立即注册") {
            router.push(UserRoutes.Register())
        }
        .font(.subheadline)
    }
}
