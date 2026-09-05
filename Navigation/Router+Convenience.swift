import AppBase
import UserModule
import ProductModule
import OrderModule

extension Router {
    func goToLogin() { navigate(UserRoutes.Login.self) }
    func goToProfile(userID: String = "user123") { navigate(UserRoutes.Profile.self, parameters: ["userID": userID]) }
    func goToProductList(category: String = "全部") { navigate(ProductRoutes.List.self, parameters: ["category": category]) }
    func goToProductDetail(productID: String) { navigate(ProductRoutes.Detail.self, parameters: ["productID": productID]) }
    func goToCart() { navigate(OrderRoutes.Cart.self) }
    func goToOrderList() { navigate(OrderRoutes.List.self) }
    func goToOrderDetail(orderID: String) { navigate(OrderRoutes.Detail.self, parameters: ["orderID": orderID]) }
}
