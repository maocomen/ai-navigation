import SwiftUI
import AppBase
import UserModule
import ProductModule
import OrderModule

@main
struct NavigationApp: App {
    @State private var router: Router<AppTab> = {
        var r = Router<AppTab>(tabs: AppTab.allCases, activeTab: .home)
        r.tabLabels = [
            .home: ("首页", "house.fill"),
            .product: ("商品", "bag.fill"),
            .order: ("订单", "shippingbox.fill"),
            .profile: ("我的", "person.fill"),
        ]
        return r
    }()

    @State private var anyRouter: AnyRouter!

    init() {
        UserModule.initialize()
        ProductModule.initialize()
        OrderModule.initialize()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(router)
                .environment(anyRouter)
                .onAppear { anyRouter = AnyRouter(router) }
        }
    }
}
