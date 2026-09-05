# Navigation 模块化路由框架 · 方案设计文档

> 版本：1.1
> 更新日期：2026-09-05
> 技术栈：Swift 5.9+ / SwiftUI / iOS 17+ / Swift Package Manager

---

## 1. 概述

Navigation 是一个 **iOS SwiftUI 模块化路由框架演示项目**，核心目标是验证并落地一整套：

- **类型安全** 的声明式路由
- **模块隔离** 的多包（Multi-Package）架构
- **字符串深度链接** 的跨模块跳转
- **各 Tab 独立栈** 管理与路由历史追踪
- **MVVM 分层** 的业务模块（Model / Repository / ViewModel / View / Routes）

项目采用「一个主应用 + 一个基础库 + N 个业务模块」的分层结构，业务模块独立编译为 Swift Package，仅依赖基础库 `AppBase`，彼此之间**无直接源码依赖**，通过 `AppBase` 提供的路由抽象实现解耦。

---

## 2. 架构总览

### 2.1 分层结构

```
┌─────────────────────────────────────────────────────┐
│                    Navigation (Host App)             │
│   NavigationApp / ContentView / HomeView / Router    │
│              （聚合所有模块，唯一的路由栈管理者）        │
└──────────────┬──────────────┬──────────────┬─────────┘
               │              │              │
        ┌──────▼─────┐ ┌──────▼─────┐ ┌──────▼─────┐
        │ UserModule │ │ProductModule│ │OrderModule │  ← 业务模块 (SPM)
        └──────┬─────┘ └──────┬─────┘ └──────┬─────┘
               │              │              │
               └──────────────┼──────────────┘
                       ┌──────▼─────┐
                       │  AppBase   │  ← 基础库 (SPM)
                       └────────────┘
```

依赖方向严格单向：**业务模块 → AppBase → 系统框架**。主应用同时依赖 AppBase 与所有业务模块。

### 2.2 目录结构

```
Navigation/
├── Navigation.xcodeproj/          # Xcode 工程
├── Navigation/                    # 主应用
│   ├── NavigationApp.swift        # @main 入口，初始化各模块
│   ├── ContentView.swift          # TabView + 独立导航栈 + 路由分发
│   ├── Router.swift               # 路由器（实现 Navigator 协议，多 Tab 栈）
│   ├── HomeView.swift             # 路由框架演示首页
│   ├── DetailView.swift           # （占位）
│   └── SettingView.swift          # （占位）
├── AppBase/                       # 基础库 (SPM)
│   ├── Package.swift
│   └── Sources/
│       ├── AppBase.swift          # 基础类 + AppConfig
│       ├── Navigator.swift        # Navigator 协议 + Environment 注入
│       ├── RouteType.swift        # RouteType 协议 + 路由工厂类型
│       ├── ModuleRegistry.swift   # 模块注册中心（含路由工厂解析 + 资源初始化）
│       ├── ModuleProtocol.swift   # 模块协议
│       ├── ModuleConfig.swift     # 模块配置
│       ├── RouteState.swift       # 路由状态 / 动作枚举
│       └── CartManager.swift      # 跨模块共享状态（购物车）
├── UserModule/                    # 用户模块 (SPM · MVVM)
│   └── Sources/
│       ├── Models/User.swift
│       ├── Repositories/UserRepository.swift
│       ├── ViewModels/UserViewModels.swift
│       ├── Views/{Login,Register,UserProfile,Settings}View.swift
│       └── UserModule.swift       # 路由定义 + 模块注册
├── ProductModule/                 # 商品模块 (SPM · MVVM)
│   └── Sources/
│       ├── Models/Product.swift
│       ├── Repositories/ProductRepository.swift
│       ├── ViewModels/ProductViewModels.swift
│       ├── Views/{ProductList,ProductDetail}View.swift
│       └── ProductModule.swift    # 路由定义 + 模块注册
├── OrderModule/                   # 订单模块 (SPM · MVVM)
│   └── Sources/
│       ├── Models/Order.swift
│       ├── Repositories/OrderRepository.swift
│       ├── ViewModels/OrderViewModels.swift
│       ├── Views/{Cart,OrderList,OrderDetail,Checkout}View.swift
│       └── OrderModule.swift      # 路由定义 + 模块注册
├── NavigationTests/               # 主应用单元测试
├── NavigationUITests/             # UI 测试
├── README_APPBASE.md              # AppBase 依赖接入说明（历史文档）
├── ROUTING_FRAMEWORK_GUIDE.md     # 路由框架指南（历史文档，部分内容已过期）
└── DESIGN.md                      # 本文档
```

---

## 3. 路由机制详解

### 3.1 核心类型职责

| 类型 | 位置 | 职责 |
|------|------|------|
| `RouteType` | AppBase/RouteType.swift | 所有路由统一遵守的协议，声明 `path` 与 `makeView()` |
| `Navigator` | AppBase/Navigator.swift | 跨模块导航抽象协议，通过 `@Environment(\.navigator)` 注入 |
| `ModuleRegistry` | AppBase/ModuleRegistry.swift | 模块与路由的注册中心，支持实例路由与工厂路由，注册时初始化模块资源 |
| `ModuleProtocol` | AppBase/ModuleProtocol.swift | 模块协议，声明 `registerRoutes` 与 `initializeResources` |
| `Router` | Navigation/Router.swift | 主应用中 `Navigator` 的 `@Observable` 实现，持有各 Tab 独立路由栈 |
| `RouteState` | AppBase/RouteState.swift | 路由历史条目与动作（push/pop/replace/reset） |
| `*Repository` | 各模块 Repositories/ | 内存态数据仓库（user/product/order），承载业务数据 CRUD |
| `*ViewModel` | 各模块 ViewModels/ | `@Observable` 逻辑层，封装校验、状态与业务编排 |

### 3.2 关键协议

```swift
public protocol RouteType: Hashable, Sendable {
    static var path: String { get }
    @MainActor func makeView() -> AnyView   // 由模块自身提供视图
}

public protocol Navigator: AnyObject {
    func push(_ route: any RouteType)
    func pop()
    func popToRoot()
    func replace(_ route: any RouteType)
    func navigate(to path: String)
    func navigate(to path: String, parameters: RouteParameters)
    var count: Int { get }
}
```

### 3.3 两种跳转方式

**（1）类型安全跳转** —— 直接构造路由实例

```swift
router.push(UserRoutes.Profile(userID: "u42"))
router.push(ProductRoutes.Detail(productID: "p3"))
```

**（2）字符串路由跳转** —— 深度链接 / 跨模块解耦

```swift
router.navigate(to: "user/profile", parameters: ["userID": "u42"])
router.navigate(to: "order/cart")   // 无参重载
```

### 3.4 参数化路由解析（路由工厂）

字符串路由通过 **路由工厂** 实现参数化构建，解决「无参预注册实例无法携带参数」的痛点：

```swift
// 模块注册时，带参路由注册工厂而非固定实例
registry.addRouteFactory("user/profile") { params in
    UserRoutes.Profile(userID: params["userID"] as? String ?? "user123")
}

// 无参路由仍可直接注册实例
registry.addRoute(OrderRoutes.Cart())
```

`ModuleRegistry.resolveRoute(for:parameters:)` 解析优先级：**工厂 > 固定实例**。

### 3.5 视图分发（数据流）

```
View 触发 →  Router.push/navigate  →  ModuleRegistry 解析  →  path.append(route)
   ↓
NavigationStack(path: $router.path)
   ↓
navigationDestination(for: AnyHashable.self)
   ↓
routeDestination(for:)  →  (value as? any RouteType)  →  route.makeView()
```

主应用通过 `AnyHashable` 动态分发，**只需识别「是否为 RouteType」并调用 `makeView()`**，无需感知任何具体路由类型——新增模块无需改动主应用。

---

## 4. 跨模块通信与状态共享

### 4.1 共享状态：`CartManager`

`ProductModule` 与 `OrderModule` 通过全局单例 `CartManager` 共享购物车状态：

- `ProductDetailView`（ProductModule）→ `CartManager.shared.addItem(...)`（`ProductDetailViewModel` 内封装）
- `CartView`（OrderModule）→ `CartViewModel` 观察 `CartManager.shared` 实时展示
- `OrderRepository.placeOrder(cart:)`（OrderModule）→ 下单时从购物车读取商品生成订单并清空购物车

```swift
public final class CartManager: ObservableObject, @unchecked Sendable {
    public static let shared = CartManager()
    @Published public var items: [CartItem] = []
    // addItem / removeItem / clear / totalCount / totalPrice
}
```

> `CartManager` 定位为「跨模块共享的购物车状态」，而订单的持久化与业务流转则由 `OrderModule` 的 `OrderRepository` 负责，二者职责分离。

### 4.2 跨模块导航

模块间跳转统一走字符串路由，`ProductModule` 无需 import `OrderModule`：

```swift
// ProductDetailView 中“查看购物车”
navigator.navigate(to: "order/cart")

// UserProfileView 中“查看订单”
navigator.navigate(to: "order/list")
```

### 4.3 模块内 MVVM 数据流

业务模块内部采用单向数据流，View 只负责渲染与导航回调，业务逻辑全部收敛到 ViewModel 与 Repository：

```
View ──用户交互──▶ ViewModel ──CRUD──▶ Repository（内存态）
  ▲                                      │
  └──────────── @Observable 响应 ────────┘
```

- **Model**：纯数据模型（`struct`），`Identifiable` / `Sendable`
- **Repository**：内存态数据仓库，单例，`@unchecked Sendable` + `NSLock` 保证线程安全
- **ViewModel**：`@Observable @MainActor`，持有 Repository 引用，封装校验与业务编排
- **View**：仅绑定 ViewModel 状态，通过 `@Environment(\.navigator)` 触发导航

---

## 5. 栈管理（各 Tab 独立栈）

主应用的 `Router` 维护**每个 Tab 独立的 `NavigationPath`**，通过当前活跃 Tab（`activeTab`）确定 `push/navigate/pop` 等操作作用于哪个栈，Tab 之间互不影响：

```swift
@Observable @MainActor
final class Router: Navigator {
    enum Tab: String, CaseIterable, Hashable, Sendable {
        case home, product, order, profile
    }
    var activeTab: Tab = .home
    private(set) var homePath = NavigationPath()
    private(set) var productPath = NavigationPath()
    private(set) var orderPath = NavigationPath()
    private(set) var profilePath = NavigationPath()

    func binding(for tab: Tab) -> Binding<NavigationPath> { ... }
    var count: Int { path(for: activeTab).count }
    // push/pop/navigate 均作用于 path(for: activeTab)
}
```

`ContentView` 通过 `TabView(selection:)` 同步 `activeTab`，各 Tab 的 `NavigationStack` 绑定各自的栈：

```swift
TabView(selection: $selectedTab) {
    tabStack(for: .home) { HomeView() }.tag(Router.Tab.home)
    tabStack(for: .product) { ProductListView(category: "全部") }.tag(Router.Tab.product)
    ...
}
.onChange(of: selectedTab) { _, newTab in router.activeTab = newTab }

private func tabStack(for tab: Router.Tab, @ViewBuilder root: () -> some View) -> some View {
    NavigationStack(path: router.binding(for: tab)) {
        root().navigationDestination(for: AnyHashable.self) { routeDestination(for: $0) }
    }
}
```

> 语义：`router.navigate(to:)` 与 `push` 均作用于**当前活跃 Tab** 的栈。位于「首页」内的全局深度链接跳转即作用于首页栈；各 Tab 内部的 `push` 只影响本 Tab 自身的栈，因此「我的」Tab 的导航栈信息面板能始终反映并操作自身栈。

---

## 6. 模块接入规范（新增一个模块）

每个业务模块按 **MVVM 分层** 组织，以新增 `PaymentModule` 为例：

```
PaymentModule/Sources/
├── Models/Payment.swift             # 数据模型
├── Repositories/PaymentRepository.swift  # 内存仓库（CRUD）
├── ViewModels/PaymentViewModels.swift    # @Observable 逻辑层
├── Views/PaymentConfirmView.swift   # UI 层（仅渲染 + 导航回调）
└── PaymentModule.swift              # 路由定义 + 模块注册
```

接入步骤：

1. **创建 SPM 包**：在项目根目录创建 `PaymentModule/`，`Package.swift` 依赖 `../AppBase`
2. **定义模型**：在 `Models/` 下定义 `struct`，遵循 `Identifiable/Sendable`
3. **实现仓库**：在 `Repositories/` 下实现内存态数据源（未来可替换为网络/DB）
4. **实现 ViewModel**：`@Observable` 封装校验、状态、业务编排，注入 Repository
5. **定义路由**：遵守 `RouteType`，实现 `path` 与 `makeView()`（带参路由用 `addRouteFactory`）
6. **实现模块**：遵守 `ModuleProtocol`，在 `registerRoutes` 注册路由、在 `initializeResources` 初始化资源
7. **启动注册**：在主应用 `NavigationApp.init()` 调用 `PaymentModule.initialize()`
8. **跳转**：通过 `router.push(...)` 或 `router.navigate(to:)`

```swift
// Repositories/PaymentRepository.swift
public final class PaymentRepository: @unchecked Sendable {
    public static let shared = PaymentRepository()
    private var records: [Payment] = []
    private init() {}
    // CRUD...
}

// ViewModels/PaymentViewModels.swift
@Observable @MainActor
public final class PaymentViewModel {
    public var orderID: String
    private let repository: PaymentRepository
    public init(orderID: String, repository: PaymentRepository = .shared) {
        self.orderID = orderID
        self.repository = repository
    }
    public func pay() async -> Bool { /* 业务逻辑 */ }
}

// PaymentModule.swift —— 路由定义 + 模块
public enum PaymentRoutes {
    public struct Confirm: RouteType {
        public static var path: String { "payment/confirm" }
        public let orderID: String
        public init(orderID: String) { self.orderID = orderID }
        public static func == (l: Confirm, r: Confirm) -> Bool { l.orderID == r.orderID }
        public func hash(into h: inout Hasher) { h.combine(orderID) }
        @MainActor public func makeView() -> AnyView { AnyView(PaymentConfirmView(orderID: orderID)) }
    }
}

public final class PaymentModule: ModuleProtocol {
    public var moduleID: String { "com.app.payment" }
    public var moduleName: String { "PaymentModule" }
    public init() {}
    public func registerRoutes(in registry: ModuleRegistry) {
        registry.addRouteFactory("payment/confirm") { params in
            guard let id = params["orderID"] as? String else { return nil }
            return PaymentRoutes.Confirm(orderID: id)
        }
    }
    public func initializeResources() {}  // 注册时由 ModuleRegistry 自动调用
    public static func initialize() {
        ModuleRegistry.shared.registerModule(PaymentModule())
    }
}
```

> 说明：`ModuleRegistry.registerModule` 会依次调用 `registerRoutes(in:)` 与 `initializeResources()`，模块无需在 `initialize()` 中手动触发资源初始化。

---

## 7. 改进记录

| # | 问题 | 改进方案 | 状态 |
|---|------|---------|------|
| 1 | `RouteType` 无 `makeView()`，视图映射硬编码在主应用 if-else 链 | 协议新增 `makeView()`，主应用改为动态分发 | ✅ |
| 2 | 字符串路由无法传参 | 引入 `RouteFactory` + `addRouteFactory` + `navigate(to:parameters:)` | ✅ |
| 3 | Tab 共享单一 `NavigationStack`，跨 Tab push 互相污染 | 每个 Tab 独立栈（`Router.Tab` + 各 `NavigationPath`），`activeTab` 驱动 | ✅ |
| 4 | 遗留死代码（RouteConfigurator/RouteNameTuple/RouteValue/RouteHistory/RouterManager） | 已删除 | ✅ |
| 5 | `ModuleRegistry.getModule` 泛型签名错误 | 改为 `getModule(_ type: T.Type)` | ✅ |
| 6 | 平台版本声明 `.iOS(.v16)` 与 `@Observable` 要求不符 | 统一改为 `.iOS(.v17)` | ✅ |
| 7 | 模块类非 final 触发 Swift 6 Sendable 警告 | 模块类改为 `final` | ✅ |
| 8 | 测试为空模板 / 引用已删类型 | 补充基础测试并修正引用 | ✅ |
| 9 | 双路由管理器并存（RouterManager 与 Router 职责重复） | 删除 RouterManager，唯一路由器为 `Router` 实现 `Navigator` | ✅ |
| 10 | 业务模块单文件混写路由/数据/视图，逻辑与 UI 未分层 | 三模块拆为 MVVM（Model/Repository/ViewModel/View/Routes） | ✅ |
| 11 | 子页面业务空泛（假数据、无交互状态） | 三模块补充内存 Repository 与完整业务流程（登录注册/搜索收藏/下单支付） | ✅ |
| 12 | `ModuleRegistry.registerModule` 未调用 `initializeResources`，模块资源不初始化 | `registerModule` 内增加 `module.initializeResources()` | ✅ |

---

## 8. 遗留问题与后续建议

以下问题基于当前代码实际状态梳理，按影响程度分为「缺陷 / 设计局限 / 技术债 / 未完成」四类。

### 8.1 缺陷（需修复）

1. **路由历史只增不减**（`Router.swift:21` / `74-92`）
   `history` 仅在 `push/replace/replaceRoot` 时追加，`pop/popToRoot` 不删除对应条目。结果是「我的」Tab 的「历史记录」数字实为累计事件数，与「栈深度」永久脱节，且随使用持续增长（仅 `clearHistory()` 可清空）。应让 `pop` 同步回退历史，或改为「历史事件流 + 当前栈快照」双模型。

2. **导航失败静默无反馈**（`Router.swift:110-114`、`HomeView.swift`）
   `navigate(to:)` 当 `resolveRoute` 返回 `nil` 时直接无操作，调用方无法得知跳转失败。`HomeView` 的深度链接提示依赖额外预判（`containsRoute`），而非真正的失败回调。建议 `navigate` 返回 `Bool` 或抛出 `Navigator` 错误，供 UI 提示。

3. **`CartManager` 与 `ModuleRegistry` 无锁且 `@unchecked Sendable`**（`CartManager.swift:4`、`ModuleRegistry.swift:5`）
   两者用 `@unchecked Sendable` 绕过编译器并发检查，内部字典/数组无任何同步。各模块 Repository 已用 `NSLock`，这三处不一致。当前单线程主操作可运行，但一旦引入多线程会产生数据竞争。建议统一改为 `actor` 或加锁。

4. **`ModuleConfig` 完全未被使用**（`ModuleConfig.swift`、`ModuleProtocol.swift:12`）
   `minVersion/maxVersion/dependencies/lazyLoad` 四个字段没有任何地方读取——`registerModule` 不做版本校验、依赖检查、懒加载。这是「定义了能力但未接线」的死字段，要么落地校验逻辑，要么删除以减噪。

### 8.2 设计局限

5. **字符串路由无法跨 Tab 定向跳转**（`Router.swift:110`）
   `navigate(to:)` 只作用于「当前活跃 Tab」。例如商品详情点「去结算」理论上应切换到订单 Tab，但当前只能落在当前 Tab 的栈内。可扩展 `navigate(to:tab:parameters:)` 并在跳转前切换 `activeTab`。

6. **`EmptyNavigator` 默认环境值会吞掉导航**（`Navigator.swift:16`）
   未注入 `navigator` 的环境默认得到无操作的 `EmptyNavigator`，导航调用被静默忽略，易在漏注入时掩盖 bug。可考虑默认值改为「断言/日志」实现，或要求显式注入。

7. **路由冲突/覆盖无检测**（`ModuleRegistry.swift:37-45`）
   `addRoute`/`addRouteFactory` 对同名 path 静默覆盖，无重复注册告警。多模块若 path 命名冲突会在不知情下互相覆盖。建议注册时检测冲突并记录日志或抛错。

### 8.3 技术债

8. **仓库数据内存态**：三个 Repository 均为内存态，应用重启丢失（注册的账号、下的订单），且商品/订单演示数据硬编码在 Repository `init` 中。后续可接 `Codable` 持久化或网络接口（Repository 边界已预留）。
9. **路由历史无持久化/导出**：`RouteState` 未遵循 `Codable`，此前 `RouteHistoryManager` 的 JSON 导出能力已随死代码删除。如需要历史埋点/回放，需补回编码支持。
10. **主应用占位文件**：`Navigation/DetailView.swift`、`Navigation/SettingView.swift` 仍为空占位，且 `SettingView` 与 UserModule 的 `SettingsView` 命名相近易混淆，建议删除或补齐。
11. **测试覆盖不足**：`AppBaseTests` 仅 `testConfig/testExample/testRouteStateInitialization` 三个浅测试；三个业务模块的 Repository/ViewModel 无任何单元测试。核心逻辑（下单、支付状态机、注册校验、路由工厂解析）值得补充。

### 8.4 未完成

12. **文档历史遗留**：`ROUTING_FRAMEWORK_GUIDE.md` 与 `README_APPBASE.md` 的目录结构、API 签名已与当前代码不符，建议同步更新或标注「以 DESIGN.md 为准」。

### 8.5 演进路线图

- **短期（缺陷修复）**：修复历史只增不减、导航失败反馈、`CartManager`/`ModuleRegistry` 线程安全、`ModuleConfig` 落地或删除。
- **中期（能力补全）**：跨 Tab 定向跳转、路由冲突检测、核心 Repository/ViewModel 单元测试、历史持久化。
- **长期（框架增强）**：URL 协议统一解析（`app://user/profile?userID=...` → `navigate`）、模块懒加载与版本/依赖校验、路由拦截/守卫（登录态校验）。

---

## 9. 验证结果

- `AppBase` / `UserModule` / `ProductModule` / `OrderModule`：`swift build` 全部成功
- `AppBase` 单元测试：3 个测试全部通过
- 主应用 `Navigation`：`xcodebuild build` 成功（`** BUILD SUCCEEDED **`）

---

## 10. 版本记录

### v1.1（2026-09-05）

**主题：业务模块 MVVM 分层与功能补全**

- 三大业务模块从「单文件混写」重构为 MVVM 分层结构（`Models/` `Repositories/` `ViewModels/` `Views/` `*Module.swift`）
- 引入内存态 Repository（`UserRepository` / `ProductRepository` / `OrderRepository`），统一 CRUD 与线程安全（`NSLock`）
- 引入 `@Observable` ViewModel，收敛校验与业务编排逻辑
- **UserModule**：新增注册/登录表单校验、登录会话、个人资料编辑、账号设置（`SettingsView`）
- **ProductModule**：新增搜索、分类筛选、收藏/取消收藏
- **OrderModule**：新增 `OrderStatus` 状态机、`CheckoutView` 结算页、下单生成真实订单、支付/取消/物流推进
- AppBase：`ModuleRegistry.registerModule` 增加 `initializeResources()` 调用，修复模块资源不初始化问题
- 文档：更新目录结构、模块接入规范（含 MVVM 示例）、新增版本记录

### v1.0（2026-09-05）

**主题：路由框架基础建设与代码清理**

- `RouteType` 协议新增 `makeView()`，主应用视图分发由硬编码 if-else 改为动态分发
- 引入 `RouteFactory` / `addRouteFactory` / `navigate(to:parameters:)`，字符串路由支持参数传递
- 删除遗留死代码（RouteConfigurator / RouteNameTuple / RouteValue / RouteHistory / RouterManager）
- 收敛双路由管理器，唯一路由器为 `Router` 实现 `Navigator`
- `Router` 改造为各 Tab 独立栈（`Router.Tab` + `activeTab` 驱动）
- 修复 `ModuleRegistry.getModule` 泛型签名、平台版本声明、Sendable 警告、空测试
