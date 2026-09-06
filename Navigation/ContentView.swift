import SwiftUI
import AppBase
import UserModule
import ProductModule
import OrderModule

enum AppTab: Hashable, CaseIterable {
    case home, product, order, profile
}

private struct AppTabRouterKey: EnvironmentKey {
    static let defaultValue = Router<AppTab>(tabs: AppTab.allCases, activeTab: .home)
}

extension EnvironmentValues {
    var router: Router<AppTab> {
        get { self[AppTabRouterKey.self] }
        set { self[AppTabRouterKey.self] = newValue }
    }
}

struct ContentView: View {
    @Environment(Router<AppTab>.self) private var router

    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            tabStack(for: .home) { HomeView() }
                .tabItem { Label("首页", systemImage: "house.fill") }
                .tag(AppTab.home)

            tabStack(for: .product) { ProductListView(category: "全部") }
                .tabItem { Label("商品", systemImage: "bag.fill") }
                .tag(AppTab.product)

            tabStack(for: .order) { OrderListView() }
                .tabItem { Label("订单", systemImage: "shippingbox.fill") }
                .tag(AppTab.order)

            tabStack(for: .profile) { ProfileTabView() }
                .tabItem { Label("我的", systemImage: "person.fill") }
                .tag(AppTab.profile)
        }
        .onChange(of: selectedTab) { _, newTab in
            router.activeTab = newTab
        }
        .overlay(alignment: .bottom) {
            RouterDebugHUD()
        }
    }

    private func tabStack(for tab: AppTab, @ViewBuilder root: () -> some View) -> some View {
        NavigationStack(path: router.binding(for: tab)) {
            root()
                .navigationDestination(for: RouteBox.self) { box in
                    box.route.makeView()
                }
        }
        .toolbar(router.isDetail(tab) ? .hidden : .visible, for: .tabBar)
    }
}

// MARK: - 我的 Tab

private struct ProfileTabView: View {
    @Environment(Router<AppTab>.self) private var router

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text("Demo User").font(.headline)
                        Text("查看个人中心").font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                .onTapGesture { router.push(UserRoutes.Profile(userID: "user123")) }
            }

            Section("快捷导航") {
                Button { router.push(UserRoutes.Login()) } label: {
                    Label("登录", systemImage: "person.crop.circle")
                }
                Button { router.push(UserRoutes.Register()) } label: {
                    Label("注册", systemImage: "person.crop.circle.badge.plus")
                }
                Button { router.push(ProductRoutes.List(category: "全部")) } label: {
                    Label("浏览商品", systemImage: "bag")
                }
                Button { router.push(OrderRoutes.Cart()) } label: {
                    Label("购物车", systemImage: "cart")
                }
            }
        }
        .navigationTitle("我的")
    }
}
