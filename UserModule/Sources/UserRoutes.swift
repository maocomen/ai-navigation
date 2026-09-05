import SwiftUI
import AppBase

// MARK: - 路由定义

public enum UserRoutes {

    public struct Login: RouteType {
        public static var path: String { "user/login" }
        public init() {}
        public static func == (lhs: Login, rhs: Login) -> Bool { true }
        public func hash(into hasher: inout Hasher) { hasher.combine("login") }
        @MainActor public func makeView() -> AnyView { AnyView(LoginView()) }
    }

    public struct Register: RouteType {
        public static var path: String { "user/register" }
        public init() {}
        public static func == (lhs: Register, rhs: Register) -> Bool { true }
        public func hash(into hasher: inout Hasher) { hasher.combine("register") }
        @MainActor public func makeView() -> AnyView { AnyView(RegisterView()) }
    }

    public struct Profile: RouteType {
        public static var path: String { "user/profile" }
        public let userID: String
        public init(userID: String) { self.userID = userID }
        public static func == (lhs: Profile, rhs: Profile) -> Bool { lhs.userID == rhs.userID }
        public func hash(into hasher: inout Hasher) { hasher.combine(userID) }
        @MainActor public func makeView() -> AnyView { AnyView(UserProfileView(userID: userID)) }
    }
}

// MARK: - 模块注册

public final class UserModule: ModuleProtocol {
    public var moduleID: String { "com.app.user" }
    public var moduleName: String { "UserModule" }
    public init() {}

    public func registerRoutes(in registry: ModuleRegistry) {
        registry.addRoute(UserRoutes.Login())
        registry.addRoute(UserRoutes.Register())
        registry.addRouteFactory("user/profile") { params in
            let userID = params["userID"] as? String ?? "user123"
            return UserRoutes.Profile(userID: userID)
        }
    }

    public func initializeResources() {}

    public static func initialize() {
        ModuleRegistry.shared.registerModule(UserModule())
    }
}

// MARK: - 登录视图

public struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var showLoginSuccess = false
    @Environment(\.navigator) private var navigator

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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

                VStack(spacing: 16) {
                    TextField("用户名", text: $username)
                        .textFieldStyle(.roundedBorder)
                    SecureField("密码", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                Button {
                    showLoginSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        navigator.pop()
                    }
                } label: {
                    Text("登录")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(username.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(username.isEmpty)
                .padding(.horizontal)

                Button("没有账号？立即注册") {
                    navigator.push(UserRoutes.Register())
                }
                .font(.subheadline)

                VStack(alignment: .leading, spacing: 8) {
                    Label("模块路由演示", systemImage: "info.circle")
                        .font(.caption.bold())
                    Text("此页面由 UserModule 独立定义\n通过 RouteType 协议注册到路由系统\n登录后自动 pop 回上一页")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
        .navigationTitle("登录")
        .alert("登录成功", isPresented: $showLoginSuccess) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("欢迎回来，\(username)！")
        }
    }
}

// MARK: - 注册视图

public struct RegisterView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @Environment(\.navigator) private var navigator

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                    .padding(.top, 24)

                VStack(spacing: 14) {
                    TextField("用户名", text: $username)
                        .textFieldStyle(.roundedBorder)
                    TextField("邮箱", text: $email)
                        .textFieldStyle(.roundedBorder)
                    SecureField("密码", text: $password)
                        .textFieldStyle(.roundedBorder)
                    SecureField("确认密码", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                let formValid = !username.isEmpty && !email.isEmpty
                    && !password.isEmpty && password == confirmPassword

                Button {
                    navigator.pop()
                } label: {
                    Text("注册并登录")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(formValid ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!formValid)
                .padding(.horizontal)
            }
        }
        .navigationTitle("注册")
    }
}

// MARK: - 用户主页视图

public struct UserProfileView: View {
    public let userID: String
    @Environment(\.navigator) private var navigator

    public init(userID: String) {
        self.userID = userID
    }

    public var body: some View {
        List {
            Section("基本信息") {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text("用户 \(userID)")
                            .font(.headline)
                        Text("user@example.com")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("账户信息") {
                LabeledContent("用户ID", value: userID)
                LabeledContent("注册时间", value: "2026-01-01")
                LabeledContent("会员等级", value: "Gold")
            }

            Section("跨模块导航演示") {
                Button("查看订单") {
                    navigator.navigate(to: "order/list")
                }
                Button("浏览商品") {
                    navigator.navigate(to: "product/list")
                }
                Button("退出登录", role: .destructive) {
                    navigator.popToRoot()
                }
            }

            Section {
                Label("通过 navigate(to:) 字符串路由跨模块跳转\n无需直接依赖其他模块",
                      systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("个人中心")
    }
}
