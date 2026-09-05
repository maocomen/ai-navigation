import SwiftUI
import AppBase
import UserModule
import ProductModule
import OrderModule

@main
struct NavigationApp: App {
    @State private var router = Router()

    init() {
        UserModule.initialize()
        ProductModule.initialize()
        OrderModule.initialize()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(router)
        }
    }
}
