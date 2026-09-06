# Navigation 模块化路由框架 · 方案设计文档

> 版本：1.9
> 更新日期：2026-09-07
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

AppBase 的 `Router` 为泛型类 `Router<Tab: Hashable>`，不耦合任何业务 Tab 定义；主应用定义自己的 `AppTab` 枚举并实例化 `Router<AppTab>`；业务模块通过 `AnyRouter`（类型擦除包装）使用导航 API，无需感知 Tab 类型。

---

## 2. 架构总览

### 2.1 分层结构

```
┌───────────────────────────────────────────────────────────────┐
│                    Navigation (Host App)                       │
│   NavigationApp / ContentView / HomeView / RouterDebugHUD     │
│   AppTab 枚举 + Router<AppTab> + AnyRouter 注入               │
└──────┬──────────────┬──────────────┬──────────────┬────────────┘
       │              │              │              │
┌──────▼─────┐ ┌──────▼─────┐ ┌──────▼─────┐ ┌──────▼─────┐
│UserContracts│ │ProductContracts│ │OrderContracts│ │   AppBase   │
│ UserLinks   │ │ ProductLinks   │ │ OrderLinks   │ │ Router<Tab> │
│             │ │               │ │ CartService  │ │ AnyRouter   │
└──────▲─────┘ └──────▲─────┘ └──────▲─────┘ │ RouterProtocol│
       │              │              │         │ ModuleRegistry│
┌──────┴─────┐ ┌──────┴─────┐ ┌──────┴─────┘ ServiceContainer│
│ UserModule │ │ProductModule│ │OrderModule │  ← 业务模块 (SPM)
│ @Env(AnyR.)│ │ @Env(AnyR.) │ │ @Env(AnyR.)│
└────────────┘ └────────────┘ └────────────┘
```

**依赖规则（单向）**：
- 业务模块 → AppBase（`AnyRouter` 类型擦除包装 + 基础设施）
- 业务模块 → 各自契约包（UserContracts / ProductContracts / OrderContracts）
- 消费方 → 对方契约包（如 ProductModule → OrderContracts），但**不依赖对方实现模块**
- 契约包之间无依赖，AppBase 无业务依赖

**AppBase 核心职责**：
- `Router<Tab: Hashable>`：泛型运行时导航引擎（push/pop/navigate + 多 Tab 栈管理 + 字符串路由桥接），不耦合业务 Tab 定义
- `AnyRouter`：类型擦除包装器，业务模块通过它使用导航 API，无需知道 Tab 类型
- `RouterProtocol`：导航 API 协议契约，`AnyRouter` 的内部实现依据
- `ModuleRegistry`：路由注册中心
- `ServiceContainer`：依赖注入容器

**契约包职责**：
- `OrderContracts`：订单域链接常量（`OrderLinks`）+ 购物车服务协议（`CartService` + `CartItem`）
- `ProductContracts`：商品域链接常量（`ProductLinks`）
- `UserContracts`：用户域链接常量（`UserLinks`）

### 2.2 目录结构

```
Navigation/
├── Navigation.xcodeproj/          # Xcode 工程
├── Navigation/                    # 主应用
│   ├── NavigationApp.swift        # @main 入口，Router<AppTab> + AnyRouter 初始化
│   ├── ContentView.swift          # AppTab 枚举 + TabView + 独立导航栈 + 路由分发
│   ├── HomeView.swift             # 路由框架演示首页
│   ├── RouterDebugHUD.swift       # 悬浮调试面板（各 Tab 栈深度/路径/操作按钮）
│   ├── DetailView.swift           # （占位）
│   └── SettingView.swift          # （占位）
├── AppBase/                       # 基础库 (SPM)
│   ├── Package.swift
│   └── Sources/
│       ├── AppBase.swift          # 基础类 + AppConfig
│       ├── Router.swift           # Router<Tab>（泛型） + RouterProtocol + AnyRouter
│       ├── RouteType.swift        # RouteType 协议 + RouteBox + 路由工厂类型
│       ├── RouteURL.swift         # 路由 URL 解析器
│       ├── ModuleRegistry.swift   # 模块注册中心（路由 + 资源初始化）
│       ├── ModuleProtocol.swift   # 模块协议
│       ├── ModuleConfig.swift     # 模块配置
│       ├── ServiceContainer.swift # 依赖注入容器（跨模块服务共享）
│       └── RouteState.swift       # 路由状态 / 动作枚举
├── OrderContracts/                 # 订单域契约包 (SPM · 链接常量 + 服务协议)
│   ├── Package.swift
│   └── Sources/
│       └── OrderContracts.swift    # OrderLinks（链接常量）+ CartService 协议 + CartItem 模型
├── ProductContracts/               # 商品域契约包 (SPM · 链接常量)
│   ├── Package.swift
│   └── Sources/
│       └── ProductContracts.swift  # ProductLinks（链接常量）
├── UserContracts/                  # 用户域契约包 (SPM · 链接常量)
│   ├── Package.swift
│   └── Sources/
│       └── UserContracts.swift     # UserLinks（链接常量）
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
│       ├── Repositories/CartServiceImpl.swift  # 购物车服务实现（实现 CartService）
│       ├── ViewModels/OrderViewModels.swift
│       ├── Views/{Cart,OrderList,OrderDetail,Checkout}View.swift
│       └── OrderModule.swift      # 路由定义 + 模块注册
├── NavigationTests/               # 主应用单元测试
├── NavigationUITests/             # UI 测试
├── README.md                      # 开发环境说明
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
| `RouteBox` | AppBase/RouteType.swift | `NavigationPath` 的统一元素包装，保证 `navigationDestination` 稳定匹配 |
| `Router<Tab>` | AppBase/Router.swift | 泛型运行时导航引擎，`paths: [Tab: NavigationPath]` 字典管理多 Tab 独立栈，通过 `@Environment(Router<Tab>.self)` 注入 |
| `RouterProtocol` | AppBase/Router.swift | 导航 API 协议契约，定义 push/pop/navigate 签名 |
| `AnyRouter` | AppBase/Router.swift | 类型擦除包装器，业务模块通过 `@Environment(AnyRouter.self)` 使用导航，无需感知 Tab 类型 |
| `AppTab` | Navigation/ContentView.swift | 主应用 Tab 枚举（`home/product/order/profile`），定义 `Router<AppTab>` 的类型参数 |
| `ModuleRegistry` | AppBase/ModuleRegistry.swift | 模块与路由的注册中心，支持实例路由与工厂路由，注册时初始化模块资源 |
| `ModuleProtocol` | AppBase/ModuleProtocol.swift | 模块协议，声明 `registerRoutes` 与 `initializeResources` |
| `RouteURL` | AppBase/RouteURL.swift | 路由 URL 解析器（scheme + caller host + path + query） |
| `ServiceContainer` | AppBase/ServiceContainer.swift | 依赖注入容器，跨模块服务按协议注册/解析 |
| `CartService` | OrderContracts/OrderContracts.swift | 购物车服务协议（订单域契约包，跨模块共享） |
| `OrderLinks` | OrderContracts/OrderContracts.swift | 订单域链接常量（单一真相源） |
| `ProductLinks` | ProductContracts/ProductContracts.swift | 商品域链接常量（单一真相源） |
| `UserLinks` | UserContracts/UserContracts.swift | 用户域链接常量（单一真相源） |
| `RouteState` | AppBase/RouteState.swift | 路由历史条目与动作（push/pop/replace/reset） |
| `RouteAction` | AppBase/RouteState.swift | 路由动作枚举（push/pop/replace/replaceRoot/reset） |
| `RouterDebugHUD` | Navigation/RouterDebugHUD.swift | 悬浮调试面板，显示各 Tab 栈深度、栈路径、操作按钮 |
| `*Repository` | 各模块 Repositories/ | 内存态数据仓库（user/product/order），承载业务数据 CRUD |
| `*ViewModel` | 各模块 ViewModels/ | `@Observable` 逻辑层，封装校验、状态与业务编排 |

### 3.2 关键类型

```swift
// RouteType 协议 - 所有路由统一遵守
public protocol RouteType: Hashable, Sendable {
    static var path: String { get }
    @MainActor func makeView() -> AnyView
}

// Router - 泛型运行时导航引擎（AppBase）
@Observable @MainActor
public final class Router<Tab: Hashable> {
    private(set) var paths: [Tab: NavigationPath]
    var activeTab: Tab
    var tabLabels: [Tab: (title: String, icon: String)]
    var pathMirrors: [Tab: [String]]

    public init(tabs: [Tab], activeTab: Tab)
    public func binding(for tab: Tab) -> Binding<NavigationPath>
    public func push(_ route: any RouteType)
    public func pop()
    public func pop(to targetCount: Int)
    public func popToRoot()
    public func replace(_ route: any RouteType)
    public func replaceRoot(_ route: any RouteType)
    public func navigate(to pathString: String)
    public func navigate(to pathString: String, parameters: RouteParameters)
    @discardableResult public func navigate(url: URL) -> Bool
    @discardableResult public func navigate(urlString: String) -> Bool
    public var count: Int { get }
    public var historyEntries: [RouteState] { get }
}

// RouterProtocol - 导航 API 协议契约
public protocol RouterProtocol: AnyObject {
    func push(_ route: any RouteType)
    func pop()
    func pop(to targetCount: Int)
    func popToRoot()
    func replace(_ route: any RouteType)
    func replaceRoot(_ route: any RouteType)
    func navigate(to pathString: String)
    @discardableResult func navigate(urlString: String) -> Bool
    @discardableResult func navigate(url: URL) -> Bool
    var count: Int { get }
    var historyEntries: [RouteState] { get }
    func clearHistory()
}

// AnyRouter - 类型擦除包装器（业务模块使用）
@Observable @MainActor
public final class AnyRouter {
    public init<R: RouterProtocol>(_ router: R)
    // 同 RouterProtocol 的全部方法签名
}

// 业务模块通过 @Environment(AnyRouter.self) 使用，无需知道 Tab 类型
```

### 3.3 三种跳转方式

**（1）类型安全跳转** —— 直接构造路由实例 push

```swift
router.push(UserRoutes.Profile(userID: "u42"))
router.push(ProductRoutes.Detail(productID: "p3"))
```

**（2）按路由类型跳转** —— 引用 `T.Type`，path 自动解析（推荐用于模块内/有依赖的场景）

```swift
router.navigate(UserRoutes.Profile.self, parameters: ["userID": "u42"])
router.navigate(OrderRoutes.Cart.self)   // Router 直接支持按类型跳转
```

**（3）URL / 字符串跳转** —— 深度链接 / 跨模块解耦

```swift
router.navigate(to: "order/cart")
router.navigate(urlString: "navigate://app.navigation.com/user/profile?userID=u42")
```

### 3.4 参数化路由解析（路由工厂）

字符串路由通过 **路由工厂** 实现参数化构建，解决「无参预注册实例无法携带参数」的痛点：

```swift
// 模块注册时，带参路由注册工厂（path 自动取自 T.path，避免二次硬编码）
registry.addRouteFactory(UserRoutes.Profile.self) { params in
    UserRoutes.Profile(userID: params["userID"] as? String ?? "user123")
}

// 无参路由仍可直接注册实例
registry.addRoute(OrderRoutes.Cart())
```

`addRouteFactory` 提供两个重载：`(T.Type)` 与 `(String)`。前者推荐，由 `T.path` 提供路径，与路由类型强绑定，不会漂移。

`ModuleRegistry.resolveRoute(for:parameters:)` 解析优先级：**工厂 > 固定实例**。

### 3.5 路由 URL 设计

统一 URL 格式：

```
<scheme>://<caller-host>/<module>/<action>?key1=value1&key2=value2
```

- **scheme**：自定义固定 scheme（当前 `navigate`），供 App 内/外深度链接
- **host**：类域名形式的 caller 标识，表示调用来源。内部调用默认 `app.navigation.com`；外部调用按来源区分：`external.navigation.com`（外部 App）、`web.navigation.com`（Web / Universal Link）、`push.navigation.com`（推送通知）、`widget.navigation.com`（小组件）、`siri.navigation.com`（Siri / 快捷指令）。host 必须在 `RouteURL.Caller` 白名单（`allHosts`）内，缺失或不在白名单时解析失败
- **path**：与 `RouteType.path` 对齐的「模块/动作」，如 `user/profile`
- **query**：路由参数，统一按 `[String: String]` 解析，类型由路由工厂二次转换

> **纯路径兼容**：不带 scheme 的纯路径 `module/action`（如 `user/profile`、`user/profile?userID=u42`）默认 `caller = app`，等价于 `navigate://app.navigation.com/...`。带 scheme 的 URL 必须显式携带合法 caller host。

示例（内部调用，caller = app）：

```
navigate://app.navigation.com/user/login
navigate://app.navigation.com/user/profile?userID=u42
navigate://app.navigation.com/product/detail?productID=p3
navigate://app.navigation.com/order/cart
navigate://app.navigation.com/order/detail?orderID=order1
```

外部来源示例（caller ≠ app）：

```
navigate://push.navigation.com/order/detail?orderID=order1
navigate://widget.navigation.com/order/cart
navigate://siri.navigation.com/user/login
```

入口：`RouteURL`（AppBase/RouteURL.swift）支持从 `URL` 或字符串解析。纯路径（无 scheme）默认 `caller = app`；带 scheme 的 URL 严格校验 scheme 与 caller host（均大小写不敏感），host 缺失或不在白名单时解析失败，`navigate(urlString:)` 返回 `false`：

```swift
router.navigate(urlString: "navigate://app.navigation.com/user/profile?userID=u42")  // Bool 返回成败
router.navigate(urlString: "user/profile?userID=u42")  // 纯路径，caller 默认 app
router.navigate(url: someURL)
```

### 3.6 path 维护策略（减少硬编码）

`RouteType.path` 是**唯一权威来源**，各层引用方式：

| 场景 | 做法 | 是否硬编码 |
|------|------|-----------|
| 模块注册路由 | `addRouteFactory(T.self)` / `addRoute(route)` | ❌ 自动取 `T.path` |
| 模块内跳转 | `navigate(T.self, parameters:)` | ❌ 自动取 `T.path` |
| 主应用便捷方法 | `goToXxx` 内 `navigate(UserRoutes.Login.self)` | ❌ 引用 `T` |
| 演示 UI 展示 | `UserRoutes.Login.path` | ❌ 引用 `T` |
| **跨模块跳转** | `navigate(to: "order/cart")` | ✅ 不可避免（模块间无依赖） |

> **跨模块字符串是深度链接的固有本质**：模块 A 不 import 模块 B，只能通过 path 字符串（即 URL 的 path 部分）跳转。这正是 `RouteURL` 存在的意义——字符串即 URL，统一走深度链接语义。结论：**不额外引入枚举/常量叠一层真相源，`RouteType.path` 即权威**。

### 3.7 视图分发（数据流）

```
View 触发 →  Router.push/navigate  →  ModuleRegistry 解析  →  path.append(RouteBox(route))
   ↓
NavigationStack(path: $router.path)
   ↓
navigationDestination(for: RouteBox.self)
   ↓
routeDestination(for:)  →  box.route.makeView()
```

> `Router.push` 将路由包装为 `RouteBox` 后再入栈。原因是 `NavigationPath` 与 `navigationDestination` 均按**具体类型**匹配，若直接 `append(any RouteType)`，元素类型是各自的具体路由类型，无法与 `AnyHashable.self` 匹配，导致二级页面不展示。统一包装为 `RouteBox` 后类型恒定，即可稳定匹配并动态解包到具体视图，主应用无需感知任何具体路由类型——新增模块无需改动主应用。

---

## 4. 跨模块通信与状态共享

跨模块通信分为两类，采用**不同策略**：

### 4.1 跨模块导航：链接常量 + 字符串路由

模块间跳转统一走**字符串路由（URL 语义）**，路径权威源收敛到各域契约包的链接常量，`ProductModule` 无需 import `OrderModule`：

```swift
// ServiceContracts：链接常量（单一真相源，换链接只改一处）
public enum OrderLinks {
    public static let cart = "order/cart"
    public static let list = "order/list"
    ...
}

// ProductDetailView 中"查看购物车"（引用契约常量，非硬编码字符串）
navigator.navigate(to: OrderLinks.cart)

// UserProfileView 中"查看订单"
navigator.navigate(to: OrderLinks.list)
```

> **路径收敛**：`RouteType.path` 也引用同一契约常量（`OrderRoutes.Cart.path → OrderLinks.cart`），确保「路由注册」与「跨模块调用」共享单一真相源，换链接改一处编译期全局生效。

### 4.2 跨模块共享状态：协议 + DI 容器

购物车状态通过 **协议/实现分离 + 依赖注入容器** 实现跨模块共享：

- **OrderContracts（契约包）**：定义 `CartService` 协议 + `CartItem` 值类型，供拥有方/消费方共同依赖
- **AppBase（基础设施层）**：`ServiceContainer`（DI 容器），只承载通用机制，不侵入业务语义
- **OrderModule（拥有方）**：`CartServiceImpl` 实现 `CartService`，在 `initializeResources` 中注册到容器
- **ProductModule（消费方）**：`ProductDetailViewModel` 只依赖 `CartService` 协议，从容器解析实例

```swift
// OrderContracts：协议（独立契约包，既不归 AppBase 也不归业务模块）
@MainActor
public protocol CartService: AnyObject { ... }

// OrderModule：实现（购物车是订单域概念，实现归归属模块）
@Observable @MainActor
public final class CartServiceImpl: CartService { ... }

// OrderModule 初始化时注册
ServiceContainer.shared.register(CartService.self, instance: CartServiceImpl.shared)

// ProductModule：按协议解析，不依赖具体类
private let cart: CartService
init(cart: CartService? = nil) {
    self.cart = cart ?? ServiceContainer.shared.resolve(CartService.self) ?? EmptyCartService()
}
```

**设计要点**：

| 原则 | 说明 |
|------|------|
| 契约独立 | `CartService` 置于 `OrderContracts` 契约包，避免基础设施层侵入业务语义 |
| 实现归位 | 购物车是订单域概念，`CartServiceImpl` 归 OrderModule |
| 面向协议 | 消费方（ProductModule）只依赖协议，可替换实现、可 mock 测试 |
| 职责分工 | `ModuleRegistry` 管**路由**，`ServiceContainer` 管**服务** |

> 为何不把 `CartService` 放 AppBase：AppBase 应保持「纯基础设施」定位，放业务契约会使其被迫感知「购物车」这一领域概念。独立契约包既让契约可独立演进，又避免消费方依赖拥有方模块。

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
- **View**：仅绑定 ViewModel 状态，通过 `@Environment(AnyRouter.self)` 触发导航

---

## 5. 栈管理（各 Tab 独立栈）

主应用的 `Router<AppTab>` 维护**每个 Tab 独立的 `NavigationPath`**，通过 `paths` 字典按 Tab 存储，当前活跃 Tab（`activeTab`）确定 `push/navigate/pop` 等操作作用于哪个栈，Tab 之间互不影响：

```swift
@Observable @MainActor
public final class Router<Tab: Hashable> {
    private(set) var paths: [Tab: NavigationPath]
    var activeTab: Tab
    var tabLabels: [Tab: (title: String, icon: String)]
    var pathMirrors: [Tab: [String]]  // 系统手势 pop 同步用

    init(tabs: [Tab], activeTab: Tab) {
        self.paths = Dictionary(uniqueKeysWithValues: tabs.map { ($0, NavigationPath()) })
        self.activeTab = activeTab
        self.tabLabels = [:]
        self.pathMirrors = [:]
    }

    func binding(for tab: Tab) -> Binding<NavigationPath> {
        Binding(get: { self.paths[tab, default: NavigationPath()] },
                set: { self.paths[tab] = $0 })
    }
    var count: Int { path(for: activeTab).count }
    // push/pop/navigate 均作用于 path(for: activeTab)
}
```

`ContentView` 定义主应用的 `AppTab` 枚举，通过 `TabView(selection:)` 同步 `activeTab`，各 Tab 的 `NavigationStack` 绑定各自的栈：

```swift
enum AppTab: Hashable, CaseIterable {
    case home, product, order, profile
}

TabView(selection: $router.activeTab) {
    tabStack(for: .home) { HomeView() }.tag(AppTab.home)
    tabStack(for: .product) { ProductListView(category: "全部") }.tag(AppTab.product)
    ...
}

private func tabStack(for tab: AppTab, @ViewBuilder root: () -> some View) -> some View {
    NavigationStack(path: router.binding(for: tab)) {
        root().navigationDestination(for: AnyHashable.self) { routeDestination(for: $0) }
    }
}
```

**业务模块的栈操作**：业务模块通过 `AnyRouter`（类型擦除包装器）调用 push/pop/navigate，无需知道 Tab 类型：

```swift
// 业务模块 View
@Environment(AnyRouter.self) private var navigator

navigator.push(UserRoutes.Profile(userID: "u42"))
navigator.popToRoot()
navigator.navigate(to: OrderLinks.cart)
```

**栈路径镜像（`pathMirrors`）**：`Router` 在每次 push/pop/replace 时显式同步 `pathMirrors`（`[Tab: [String]]`），用于调试面板展示各 Tab 栈内路由路径。系统手势触发的 pop 通过 `setPath` 的 count-diff 同步更新镜像。

> 语义：`router.navigate(to:)` 与 `push` 均作用于**当前活跃 Tab** 的栈。位于「首页」内的全局深度链接跳转即作用于首页栈；各 Tab 内部的 `push` 只影响本 Tab 自身的栈。`RouterDebugHUD` 显示各 Tab 的栈深度与路径。

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
| 13 | `Router` 硬编码 Tab 枚举和路径属性，新增/删除 Tab 需改 AppBase | `Router<Tab: Hashable>` 泛型化，`paths` 字典替代硬编码属性；`AnyRouter` 类型擦除供业务模块使用；`RouterProtocol` 定义 API 契约；主应用定义 `AppTab` 枚举 | ✅ |
| 14 | 业务模块通过 `@Environment(Router.self)` 直接依赖 AppBase 具体类 | 业务模块改用 `@Environment(AnyRouter.self)`，通过类型擦除包装器解耦 | ✅ |
| 15 | 无调试面板，各 Tab 栈状态不可见 | 新增 `RouterDebugHUD` 悬浮面板，显示各 Tab 栈深度、栈路径、操作按钮 | ✅ |
| 16 | 系统手势 pop 后栈路径镜像不同步 | `push/pop/replace/replaceRoot` 显式同步 `pathMirrors`；`setPath` count-diff 同步系统手势 pop | ✅ |

---

## 8. 遗留问题与后续建议

以下问题基于当前代码实际状态梳理，按影响程度分为「缺陷 / 设计局限 / 技术债 / 未完成」四类。

### 8.1 缺陷（需修复）

1. **路由历史只增不减**（`Router.swift:21` / `74-92`）
   `history` 仅在 `push/replace/replaceRoot` 时追加，`pop/popToRoot` 不删除对应条目。结果是「我的」Tab 的「历史记录」数字实为累计事件数，与「栈深度」永久脱节，且随使用持续增长（仅 `clearHistory()` 可清空）。应让 `pop` 同步回退历史，或改为「历史事件流 + 当前栈快照」双模型。
   **状态：✅ 已修复** — `pop/pop(to:)/popToRoot` 现在记录 `.pop` action 到 history。

2. **导航失败静默无反馈**（`Router.swift:110-114`、`HomeView.swift`）
   `navigate(to:)` 当 `resolveRoute` 返回 `nil` 时直接无操作，调用方无法得知跳转失败。`HomeView` 的深度链接提示依赖额外预判（`containsRoute`），而非真正的失败回调。建议 `navigate` 返回 `Bool` 或抛出 `Navigator` 错误，供 UI 提示。
   **状态：✅ 已修复** — `navigate(to:)` 系列方法现在返回 `Bool`。

3. **`CartManager` 与 `ModuleRegistry` 无锁且 `@unchecked Sendable`**（`CartManager.swift:4`、`ModuleRegistry.swift:5`）
   两者用 `@unchecked Sendable` 绕过编译器并发检查，内部字典/数组无任何同步。各模块 Repository 已用 `NSLock`，这三处不一致。当前单线程主操作可运行，但一旦引入多线程会产生数据竞争。建议统一改为 `actor` 或加锁。
   **状态：ℹ️ 无需修改** — 所有访问均在主线程，加锁反而引入死锁风险。

4. **`ModuleConfig` 完全未被使用**（`ModuleConfig.swift`、`ModuleProtocol.swift:12`）
   `minVersion/maxVersion/dependencies/lazyLoad` 四个字段没有任何地方读取——`registerModule` 不做版本校验、依赖检查、懒加载。这是「定义了能力但未接线」的死字段，要么落地校验逻辑，要么删除以减噪。
   **状态：✅ 已修复** — 删除 `ModuleConfig.swift`，移除 `ModuleProtocol.config` 属性。

### 8.2 设计局限

5. **字符串路由无法跨 Tab 定向跳转**（`Router.swift:110`）
   `navigate(to:)` 只作用于「当前活跃 Tab」。例如商品详情点「去结算」理论上应切换到订单 Tab，但当前只能落在当前 Tab 的栈内。可扩展 `navigate(to:tab:parameters:)` 并在跳转前切换 `activeTab`。
   **状态：✅ 已修复** — 新增 `push(_:to:)` 和 `navigate(to:in:)` 方法，支持跨 Tab 定向跳转并自动切换 `activeTab`。

6. **`EmptyNavigator` 默认环境值会吞掉导航**（`Navigator.swift:16`）
   未注入 `navigator` 的环境默认得到无操作的 `EmptyNavigator`，导航调用被静默忽略，易在漏注入时掩盖 bug。可考虑默认值改为「断言/日志」实现，或要求显式注入。
   **状态：ℹ️ 不适用** — v1.6 已删除 `Navigator` 协议，业务模块直接使用 `AnyRouter`。

7. **路由冲突/覆盖无检测**（`ModuleRegistry.swift:37-45`）
   `addRoute`/`addRouteFactory` 对同名 path 静默覆盖，无重复注册告警。多模块若 path 命名冲突会在不知情下互相覆盖。建议注册时检测冲突并记录日志或抛错。
   **状态：✅ 已修复** — `addRoute`/`addRouteFactory` 现在检测冲突并打印警告日志。

### 8.3 技术债

8. **仓库数据内存态**：三个 Repository 均为内存态，应用重启丢失（注册的账号、下的订单），且商品/订单演示数据硬编码在 Repository `init` 中。后续可接 `Codable` 持久化或网络接口（Repository 边界已预留）。
9. **路由历史无持久化/导出**：`RouteState` 未遵循 `Codable`，此前 `RouteHistoryManager` 的 JSON 导出能力已随死代码删除。如需要历史埋点/回放，需补回编码支持。
10. **主应用占位文件**：`Navigation/DetailView.swift`、`Navigation/SettingView.swift` 仍为空占位，且 `SettingView` 与 UserModule 的 `SettingsView` 命名相近易混淆，建议删除或补齐。
   **状态：✅ 已修复** — 删除两个空占位文件。
11. **测试覆盖不足**：`AppBaseTests` 仅 `testConfig/testExample/testRouteStateInitialization` 三个浅测试；三个业务模块的 Repository/ViewModel 无任何单元测试。核心逻辑（下单、支付状态机、注册校验、路由工厂解析）值得补充。

### 8.4 未完成

12. **文档历史遗留**：`ROUTING_FRAMEWORK_GUIDE.md` 与 `README_APPBASE.md` 的目录结构、API 签名已与当前代码不符，建议同步更新或标注「以 DESIGN.md 为准」。
   **状态：✅ 已修复** — 两个文件已不存在（此前已清理）。

### 8.5 演进路线图

- **短期（缺陷修复）**：✅ 历史只增不减、导航失败反馈、`ModuleConfig` 删除已完成。`ModuleRegistry` 无需加锁（主线程访问）。
- **中期（能力补全）**：✅ 跨 Tab 定向跳转、路由冲突检测已完成。剩余：核心 Repository/ViewModel 单元测试、历史持久化。
- **长期（框架增强）**：URL 协议统一解析（`app://user/profile?userID=...` → `navigate`）、模块懒加载与版本/依赖校验、路由拦截/守卫（登录态校验）。

---

## 9. 验证结果

- `AppBase` / `UserModule` / `ProductModule` / `OrderModule`：`swift build` 全部成功
- `AppBase` 单元测试：19 个测试全部通过（RouteURL 16 + RouteState 1 + AppBase 2）
- 主应用 `Navigation`：`xcodebuild build` 成功（`** BUILD SUCCEEDED **`）

---

## 10. 版本记录

### v1.9（2026-09-07）

**主题：缺陷修复 + 能力补全 + 代码整洁**

- **历史只增不减修复**：`pop()`/`pop(to:)`/`popToRoot()` 现在记录 `.pop` action 到 history，栈深度与历史条目保持同步
- **导航失败反馈**：`navigate(to:)` 系列方法返回 `Bool`，失败返回 `false` 供调用方判断
- **跨 Tab 定向跳转**：新增 `push(_:to:)` 和 `navigate(to:in:)` 方法，支持跳转到指定 Tab 并自动切换 `activeTab`
- **路由冲突检测**：`addRoute`/`addRouteFactory` 检测同名 path 冲突并打印警告日志
- **删除 ModuleConfig**：移除未使用的 `ModuleConfig` 结构体和 `ModuleProtocol.config` 属性
- **删除占位文件**：移除空占位的 `DetailView.swift` 和 `SettingView.swift`
- **清理过期文档**：`ROUTING_FRAMEWORK_GUIDE.md` 和 `README_APPBASE.md` 已不存在
- 文档：更新第 8 节遗留问题状态、演进路线图、版本记录

### v1.8（2026-09-06）

**主题：Router 泛型化（Tab 解耦）+ 调试面板**

- `Router` 改为泛型 `Router<Tab: Hashable>`，`paths` 字典 `[Tab: NavigationPath]` 替代硬编码路径属性（`homePath`/`productPath` 等）
- AppBase 不再耦合任何业务 Tab 定义，新增/删除 Tab 只改主应用 `AppTab` 枚举
- 新增 `RouterProtocol`：导航 API 协议契约，定义 push/pop/navigate 签名
- 新增 `AnyRouter`：类型擦除包装器，业务模块通过 `@Environment(AnyRouter.self)` 使用导航，无需感知 Tab 类型
- 主应用 `ContentView` 定义 `AppTab` 枚举（`home/product/order/profile`），通过 `AppTabRouterKey` 注册 EnvironmentKey
- `NavigationApp` 同时注入 `Router<AppTab>` 和 `AnyRouter(router)`
- 10 个业务模块 View：`@Environment(Router.self)` → `@Environment(AnyRouter.self)`
- 新增 `RouterDebugHUD`（悬浮调试面板）：可折叠浮窗，显示各 Tab 栈深度、栈路径、Pop/PopToRoot/Clear 操作按钮、最近 20 条历史记录
- `ContentView` 挂载 HUD overlay（ZStack 层级），移除 ProfileTabView 内嵌的「导航栈信息」区块
- `HomeView` 简化为纯导航演示（移除历史列表区块，HUD 已覆盖）
- `README.md` 新增开发环境说明（macOS 26.6.2 / Xcode 27.0 / Swift 5.9+ / iOS 17+）
- `project.pbxproj` 修复 objectVersion 77 兼容性（Xcode 自动升级 110 后手动回退）
- 文档：更新架构图、目录结构、核心类型表、栈管理章节、模块接入规范、验证结果

### v1.7（2026-09-06）

**主题：深度链接 URL 规范化（caller host）**

- `RouteURL` 统一深度链接格式为 `navigate://<caller-host>/<module>/<action>?key=value`，host 为类域名形式的调用来源（caller）标识
- 内部调用默认 `app.navigation.com`；外部调用按来源区分：`external.navigation.com`（外部 App）、`web.navigation.com`（Web / Universal Link）、`push.navigation.com`（推送通知）、`widget.navigation.com`（小组件）、`siri.navigation.com`（Siri / 快捷指令）
- 纯路径 `module/action`（无 scheme）向后兼容，默认 `caller = app`
- 带 scheme 的 URL 必须显式携带白名单（`RouteURL.Caller.allHosts`）内的 caller host，缺失或非法 host 解析失败（fail loud），旧格式 `navigate://user/login` 不再被支持
- 文档：更新第 3.3 / 3.5 节 URL 示例与格式说明、核心类型表 `RouteURL` 职责

### v1.6（2026-09-05）

**主题：Router 下沉到 AppBase + 删除 Navigator 协议**

- `Router` 从主应用下沉到 AppBase 作为具体类（`public final class Router`）
- 删除 `Navigator` 协议（不再需要抽象层），业务模块直接通过 `@Environment(Router.self)` 获取 Router 实例
- 便捷方法（`goToXxx`）作为 Router 扩展留在主应用（`Router+Convenience.swift`），隔离业务模块依赖
- 10 个业务模块 View：`@Environment(\.navigator)` → `@Environment(Router.self)`
- `NavigationApp.swift` 简化为只注入 `.environment(router)`
- 文档：更新架构图、目录结构、核心类型表、删除 Navigator 相关描述

### v1.5（2026-09-05）

**主题：每模块独立契约包 + 链接常量 + path 收敛**

- 废弃 `ServiceContracts` 统一契约包，拆分为三个域契约包：`OrderContracts`、`ProductContracts`、`UserContracts`
- 每个契约包内维护「链接常量」（`OrderLinks` / `ProductLinks` / `UserLinks`），跨模块跳转引用常量而非裸字符串
- `RouteType.path` 收敛到契约常量（`OrderRoutes.Cart.path → OrderLinks.cart`），路由注册与跨模块调用共享单一真相源
- `CartService` + `CartItem` 迁入 `OrderContracts`（购物车属订单域）
- 消费方（ProductView → 购物车、CartView → 商品列表等）改引用 `*Links` 常量
- `project.pbxproj` 移除 ServiceContracts 引用，新增三个契约包引用
- 文档：更新分层结构图、目录结构、第 4 章（链接常量 + path 收敛）、核心类型表

### v1.4（2026-09-05）

**主题：跨模块契约拆分为独立 ServiceContracts 包**

- 新增 `ServiceContracts` SPM 包，承载跨模块共享契约（`CartService` 协议 + `CartItem` 模型）
- `CartService` 从 AppBase 迁出，AppBase 回归纯基础设施职责（不再侵入业务语义）
- ProductModule / OrderModule 增加 `../ServiceContracts` 依赖，源文件补 `import ServiceContracts`
- 主应用 `project.pbxproj` 注册 `ServiceContracts` 本地包引用
- 文档：更新分层结构图、目录结构、第 4.2 章、核心类型表

### v1.3（2026-09-05）

**主题：跨模块共享状态引入协议/实现分离 + 依赖注入容器**

- 跨模块通信分两类治理：**导航走字符串路由**（保留深度链接语义，不引入导航协议层），**状态共享走协议 + DI**
- AppBase 新增 `CartService` 协议 + `CartItem` 值类型 + `ServiceContainer`（轻量 DI 容器，管服务）
- OrderModule 新增 `CartServiceImpl` 实现 `CartService`，`initializeResources` 时注册到容器
- ProductModule `ProductDetailViewModel` 改为依赖 `CartService` 协议（从容器解析），实现可替换、可 mock
- OrderModule `OrderRepository.placeOrder(cart:)` 参数改为 `CartService` 协议
- 删除 AppBase `CartManager` 具体类（迁移为 `CartServiceImpl`）
- 文档：更新第 4 章跨模块通信、目录结构、核心类型表

### v1.2（2026-09-05）

**主题：二级页面展示修复、TabBar 显隐、路由 URL 与 path 收敛**

- 修复二级页面不展示：引入 `RouteBox` 统一 `NavigationPath` 元素类型，`navigationDestination(for: RouteBox.self)` 稳定匹配
- TabBar 隐显提至 `NavigationStack` 层（`Router.isDetail` 驱动），推送转场与 tabBar 收起合并为同一动画
- 新增 `RouteURL` 解析器与 `Router.navigate(url:)` / `navigate(urlString:)`（返回成败）；URL 格式自 v1.7 起规范为 `navigate://<caller-host>/module/action?k=v`
- path 收敛：`RouteType.path` 为唯一权威源，`addRouteFactory(T.self)`、`navigate(T.self)` 消除硬编码；跨模块字符串保留为深度链接语义
- 便捷方法 `goToXxx` 引用各模块 `T.path`；演示 UI 展示改用 `T.path`
- 文档：扩充路由机制（URL 设计、path 维护策略、三种跳转方式）

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
