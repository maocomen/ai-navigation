# Navigation 模块化路由框架 · 方案设计文档

> 版本：1.0
> 更新日期：2026-09-05
> 技术栈：Swift 5.9+ / SwiftUI / iOS 17+ / Swift Package Manager

---

## 1. 概述

Navigation 是一个 **iOS SwiftUI 模块化路由框架演示项目**，核心目标是验证并落地一整套：

- **类型安全** 的声明式路由
- **模块隔离** 的多包（Multi-Package）架构
- **字符串深度链接** 的跨模块跳转
- **统一栈管理** 与路由历史追踪

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
│   ├── ContentView.swift          # TabView + 统一导航栈 + 路由分发
│   ├── Router.swift               # 路由器（实现 Navigator 协议）
│   ├── HomeView.swift             # 路由框架演示首页
│   ├── DetailView.swift           # （占位）
│   └── SettingView.swift          # （占位）
├── AppBase/                       # 基础库 (SPM)
│   ├── Package.swift
│   └── Sources/
│       ├── AppBase.swift          # 基础类 + AppConfig
│       ├── Navigator.swift        # Navigator 协议 + Environment 注入
│       ├── RouteType.swift        # RouteType 协议 + 路由工厂类型
│       ├── ModuleRegistry.swift   # 模块注册中心（含路由工厂解析）
│       ├── ModuleProtocol.swift   # 模块协议
│       ├── ModuleConfig.swift     # 模块配置
│       ├── RouteState.swift       # 路由状态 / 动作枚举
│       └── CartManager.swift      # 跨模块共享状态示例（购物车）
├── UserModule/                    # 用户模块 (SPM)
│   └── Sources/UserRoutes.swift   # Login/Register/Profile 路由 + 视图
├── ProductModule/                 # 商品模块 (SPM)
│   └── Sources/ProductRoutes.swift # List/Detail 路由 + 视图
├── OrderModule/                   # 订单模块 (SPM)
│   └── Sources/OrderRoutes.swift   # Cart/List/Detail 路由 + 视图
├── NavigationTests/               # 主应用单元测试
├── NavigationUITests/             # UI 测试
├── README_APPBASE.md              # AppBase 依赖接入说明（历史文档）
└── ROUTING_FRAMEWORK_GUIDE.md     # 路由框架指南（历史文档，部分内容已过期）
```

---

## 3. 路由机制详解

### 3.1 核心类型职责

| 类型 | 位置 | 职责 |
|------|------|------|
| `RouteType` | AppBase/RouteType.swift | 所有路由统一遵守的协议，声明 `path` 与 `makeView()` |
| `Navigator` | AppBase/Navigator.swift | 跨模块导航抽象协议，通过 `@Environment(\.navigator)` 注入 |
| `ModuleRegistry` | AppBase/ModuleRegistry.swift | 模块与路由的注册中心，支持实例路由与工厂路由 |
| `Router` | Navigation/Router.swift | 主应用中 `Navigator` 的 `@Observable` 实现，持有唯一路由栈 |
| `RouteState` | AppBase/RouteState.swift | 路由历史条目与动作（push/pop/replace/reset） |

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

- `ProductDetailView`（ProductModule）→ `CartManager.shared.addItem(...)`
- `CartView`（OrderModule）→ `@ObservedObject CartManager.shared` 实时展示

```swift
public final class CartManager: ObservableObject, @unchecked Sendable {
    public static let shared = CartManager()
    @Published public var items: [CartItem] = []
    // addItem / removeItem / clear / totalCount / totalPrice
}
```

### 4.2 跨模块导航

模块间跳转统一走字符串路由，`ProductModule` 无需 import `OrderModule`：

```swift
// ProductDetailView 中“查看购物车”
navigator.navigate(to: "order/cart")

// UserProfileView 中“查看订单”
navigator.navigate(to: "order/list")
```

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

以新增 `PaymentModule` 为例：

1. **创建 SPM 包**：在项目根目录创建 `PaymentModule/`，`Package.swift` 依赖 `../AppBase`
2. **定义路由**：遵守 `RouteType`，实现 `path` 与 `makeView()`
3. **实现模块**：遵守 `ModuleProtocol`，在 `registerRoutes` 中注册（带参路由用 `addRouteFactory`）
4. **提供视图**：在模块内定义 SwiftUI 视图
5. **启动注册**：在主应用 `NavigationApp.init()` 调用 `PaymentModule.initialize()`
6. **跳转**：通过 `router.push(...)` 或 `router.navigate(to:)`

```swift
// Packet 精简写法参考
public struct PaymentRoutes {
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
    public static func initialize() {
        ModuleRegistry.shared.registerModule(PaymentModule())
    }
}
```

---

## 7. 本次改进记录

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

---

## 8. 遗留问题与后续建议

### 8.1 尚待优化的点

1. **`@unchecked Sendable` 掩盖并发风险**：`ModuleRegistry`（无锁字典）与 `CartManager`（无锁数组）均以 `@unchecked Sendable` 绕过检查。当前主线程单线程访问可接受，但若引入多线程需改为锁/actor 或拆分为值类型。
2. **路由历史仅存 `RouteState`，未整合 JSON 导出/导入**：此前 `RouteHistoryManager` 具备导出能力但已删除，如需要持久化历史可考虑在 `Router` 中补回 `Codable` 支持。
3. **字符串路由跳转的落点**：`navigate(to:)` 始终作用于「当前活跃 Tab」。若后续需要「跨 Tab 定向跳转」（例如在商品页点「去结算」自动切到订单 Tab），可扩展 `navigate(to:tab:parameters:)` 指定目标 Tab 并切换 `activeTab`。
4. **文档历史遗留**：`ROUTING_FRAMEWORK_GUIDE.md` 与 `README_APPBASE.md` 中的目录结构、API 签名已与当前代码不符，建议后续同步更新或标注「以 DESIGN.md 为准」。

### 8.2 演进路线图

- **短期**：补充 `ModuleRegistry` 路由冲突检测、版本校验（`ModuleConfig` 已预留字段）；为 `RouteType.makeView` 与参数解析补单元测试。
- **中期**：将 `Router` 历史记录接入持久化；引入路由拦截/守卫（登录态校验等）。
- **长期**：支持 URL 协议统一解析（`app://user/profile?userID=...` → `navigate`）；模块懒加载（`ModuleConfig.lazyLoad`）。

---

## 9. 验证结果

- `AppBase` / `UserModule` / `ProductModule` / `OrderModule`：`swift build` 全部成功
- `AppBase` 单元测试：3 个测试全部通过
- 主应用 `Navigation`：`xcodebuild build` 成功（`** BUILD SUCCEEDED **`）
