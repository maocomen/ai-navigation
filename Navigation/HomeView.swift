import SwiftUI
import AppBase
import UserModule
import ProductModule
import OrderModule

struct HomeView: View {
    @Environment(Router<AppTab>.self) private var router
    @State private var deepLinkPath = ""
    @State private var showDeepLinkAlert = false
    @State private var deepLinkResult = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 路由框架概览
                headerSection

                // 深度链接演示
                deepLinkSection

                // 模块快捷入口
                moduleSection

                // 跨模块导航演示
                crossModuleSection

                // 导航操作演示
                operationSection
            }
            .padding()
        }
        .navigationTitle("路由框架演示")
        .alert(deepLinkResult, isPresented: $showDeepLinkAlert) {
            Button("确定", role: .cancel) {}
        }
    }

    // MARK: - 头部

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.triangle.branch")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
            Text("模块化路由框架")
                .font(.title2.bold())
            Text("类型安全 · 模块隔离 · 深度链接 · 栈管理")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - 深度链接

    private var deepLinkSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("深度链接 (Deep Link)", systemImage: "link")
                .font(.headline)

            Text("输入路由路径或 URL，如 user/login 或 navigate://app.navigation.com/user/profile?userID=u42")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                TextField("如 user/login 或 navigate://app.navigation.com/user/profile?userID=u42", text: $deepLinkPath)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                    .autocapitalization(.none)

                Button("跳转") {
                    let input = deepLinkPath
                    if router.navigate(urlString: input) {
                        deepLinkResult = jumpSuccessMessage(for: input)
                    } else {
                        deepLinkResult = "❌ 未找到路由: \(input)"
                    }
                    showDeepLinkAlert = true
                    deepLinkPath = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(deepLinkPath.isEmpty)
            }

            // 预设深度链接
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    DeepLinkChip(title: "登录", path: "navigate://app.navigation.com/\(UserRoutes.Login.path)") { deepLinkPath = $0 }
                    DeepLinkChip(title: "注册", path: "navigate://app.navigation.com/\(UserRoutes.Register.path)") { deepLinkPath = $0 }
                    DeepLinkChip(title: "个人中心", path: "navigate://app.navigation.com/\(UserRoutes.Profile.path)") { deepLinkPath = $0 }
                    DeepLinkChip(title: "商品列表", path: "navigate://app.navigation.com/\(ProductRoutes.List.path)") { deepLinkPath = $0 }
                    DeepLinkChip(title: "购物车", path: "navigate://app.navigation.com/\(OrderRoutes.Cart.path)") { deepLinkPath = $0 }
                    DeepLinkChip(title: "订单列表", path: "navigate://app.navigation.com/\(OrderRoutes.List.path)") { deepLinkPath = $0 }

                    DeepLinkChip(title: "外部-个人中心", path: "navigate://external.navigation.com/\(UserRoutes.Profile.path)?userID=u42") { deepLinkPath = $0 }
                    DeepLinkChip(title: "推送-订单", path: "navigate://push.navigation.com/\(OrderRoutes.Detail.path)?orderID=ORD-123") { deepLinkPath = $0 }
                    DeepLinkChip(title: "Web-商品", path: "navigate://web.navigation.com/\(ProductRoutes.Detail.path)?productID=p3") { deepLinkPath = $0 }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - 模块入口

    private var moduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("已注册模块", systemImage: "puzzlepiece.fill")
                .font(.headline)

            ModuleCard(
                icon: "person.2.fill", color: .blue,
                title: "UserModule", routeCount: 3,
                routes: [UserRoutes.Login.path, UserRoutes.Register.path, UserRoutes.Profile.path]
            )

            ModuleCard(
                icon: "bag.fill", color: .green,
                title: "ProductModule", routeCount: 2,
                routes: [ProductRoutes.List.path, ProductRoutes.Detail.path]
            )

            ModuleCard(
                icon: "shippingbox.fill", color: .orange,
                title: "OrderModule", routeCount: 3,
                routes: [OrderRoutes.Cart.path, OrderRoutes.List.path, OrderRoutes.Detail.path]
            )
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - 跨模块导航

    private var crossModuleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("跨模块导航演示", systemImage: "arrow.triangle.2.circlepath")
                .font(.headline)

            Text("模块之间互相导航，无需直接依赖")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                CrossModuleButton(
                    title: "UserModule → 查看订单",
                    subtitle: "用户中心跳转到订单模块",
                    icon: "arrow.right.circle.fill",
                    color: .purple
                ) {
                    router.push(OrderRoutes.List())
                }

                CrossModuleButton(
                    title: "ProductModule → 加入购物车",
                    subtitle: "商品详情跳转到购物车（跨模块状态共享）",
                    icon: "arrow.right.circle.fill",
                    color: .green
                ) {
                    router.push(ProductRoutes.Detail(productID: "p1"))
                }

                CrossModuleButton(
                    title: "OrderModule → 浏览商品",
                    subtitle: "购物车为空时跳转到商品列表",
                    icon: "arrow.right.circle.fill",
                    color: .orange
                ) {
                    router.push(ProductRoutes.List(category: "全部"))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - 导航操作演示

    private var operationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("导航操作演示", systemImage: "hand.tap")
                .font(.headline)

            Text("从首页发起导航，观察底部调试 HUD 的栈变化")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                StackButton(title: "Push 登录", icon: "arrow.down") {
                    router.push(UserRoutes.Login())
                }
                StackButton(title: "Push 商品", icon: "arrow.down") {
                    router.push(ProductRoutes.List(category: "全部"))
                }
                StackButton(title: "Replace Root", icon: "arrow.triangle.2.circlepath") {
                    router.replaceRoot(UserRoutes.Login())
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    /// 跳转成功提示文案
    ///
    /// `Router.navigate(urlString:)` 只返回 Bool，拿不到解析结果；
    /// 这里用 `RouteURL.parse` 复现解析，展示 caller 与归一化 path（附原始输入）。
    private func jumpSuccessMessage(for input: String) -> String {
        guard case .success(let parsed) = RouteURL.parse(input) else {
            return "✅ 已跳转到: \(input)"
        }
        return "✅ 已跳转到: [\(parsed.caller.rawValue)] \(parsed.path)\n（输入: \(input)）"
    }
}

// MARK: - 子组件

private struct DeepLinkChip: View {
    let title: String
    let path: String
    let onSelect: (String) -> Void

    var body: some View {
        Button {
            onSelect(path)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                Text(path)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
        }
    }
}

private struct ModuleCard: View {
    let icon: String
    let color: Color
    let title: String
    let routeCount: Int
    let routes: [String]

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(color)
                .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text("\(routeCount) 个路由: \(routes.joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
    }
}

private struct CrossModuleButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
    }
}

private struct StackButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
    }
}
