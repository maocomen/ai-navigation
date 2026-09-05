import SwiftUI
import AppBase
import UserModule
import ProductModule
import OrderModule

struct HomeView: View {
    @Environment(Router.self) private var router
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

                // 栈控制
                stackControlSection

                // 路由历史
                historySection
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

            Text("输入路由路径，模拟 URL Scheme / Push Notification 跳转")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                TextField("输入路由路径，如 user/login", text: $deepLinkPath)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                    .autocapitalization(.none)

                Button("跳转") {
                    if registry.containsRoute(deepLinkPath) {
                        router.navigate(to: deepLinkPath)
                        deepLinkResult = "✅ 已跳转到: \(deepLinkPath)"
                    } else {
                        deepLinkResult = "❌ 未找到路由: \(deepLinkPath)"
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
                    DeepLinkChip(title: "登录", path: "user/login") { deepLinkPath = $0 }
                    DeepLinkChip(title: "注册", path: "user/register") { deepLinkPath = $0 }
                    DeepLinkChip(title: "个人中心", path: "user/profile") { deepLinkPath = $0 }
                    DeepLinkChip(title: "商品列表", path: "product/list") { deepLinkPath = $0 }
                    DeepLinkChip(title: "购物车", path: "order/cart") { deepLinkPath = $0 }
                    DeepLinkChip(title: "订单列表", path: "order/list") { deepLinkPath = $0 }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var registry: ModuleRegistry { ModuleRegistry.shared }

    // MARK: - 模块入口

    private var moduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("已注册模块", systemImage: "puzzlepiece.fill")
                .font(.headline)

            ModuleCard(
                icon: "person.2.fill", color: .blue,
                title: "UserModule", routeCount: 3,
                routes: ["user/login", "user/register", "user/profile"]
            )

            ModuleCard(
                icon: "bag.fill", color: .green,
                title: "ProductModule", routeCount: 2,
                routes: ["product/list", "product/detail"]
            )

            ModuleCard(
                icon: "shippingbox.fill", color: .orange,
                title: "OrderModule", routeCount: 3,
                routes: ["order/cart", "order/list", "order/detail"]
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

    // MARK: - 栈控制

    private var stackControlSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("导航栈控制", systemImage: "stack")
                    .font(.headline)
                Spacer()
                Text("深度: \(router.count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }

            Text("当前栈: \(router.stackDescription)")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                StackButton(title: "Push 登录", icon: "arrow.down") {
                    router.push(UserRoutes.Login())
                }
                StackButton(title: "Push 商品", icon: "arrow.down") {
                    router.push(ProductRoutes.List(category: "全部"))
                }
                StackButton(title: "Pop 返回", icon: "arrow.up") {
                    router.pop()
                }
                StackButton(title: "Pop to Root", icon: "arrow.up.to.line") {
                    router.popToRoot()
                }
                StackButton(title: "Replace Root", icon: "arrow.triangle.2.circlepath") {
                    router.replaceRoot(UserRoutes.Login())
                }
                StackButton(title: "清空历史", icon: "trash") {
                    router.clearHistory()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - 路由历史

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("路由历史 (\(router.historyEntries.count))", systemImage: "clock.arrow.circlepath")
                .font(.headline)

            if router.historyEntries.isEmpty {
                Text("暂无导航历史")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(router.historyEntries.suffix(8).enumerated(), id: \.offset) { _, entry in
                    HStack {
                        Image(systemName: actionIcon(entry.action))
                            .font(.caption)
                            .foregroundColor(actionColor(entry.action))
                            .frame(width: 20)
                        Text(entry.path)
                            .font(.caption.monospaced())
                        Spacer()
                        Text(entry.action.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(actionColor(entry.action).opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func actionIcon(_ action: RouteAction) -> String {
        switch action {
        case .push: return "arrow.down"
        case .pop: return "arrow.up"
        case .replace: return "arrow.triangle.2.circlepath"
        case .reset: return "arrow.clockwise"
        }
    }

    private func actionColor(_ action: RouteAction) -> Color {
        switch action {
        case .push: return .blue
        case .pop: return .orange
        case .replace: return .purple
        case .reset: return .red
        }
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
