# Navigation

SwiftUI 路由框架 Demo — MVVM + 协议驱动 + URL 路由

## 开发环境

| 项目 | 版本 |
|------|------|
| macOS | 26.6.2 |
| Xcode | 27.0 (Build 27A5252f) |
| Swift | 5.9+ |
| iOS Deployment Target | 17.0+ |

## 项目结构

```
Navigation/              ← 宿主 App（App 壳 + TabView）
├── AppBase/             ← Router 核心 + RouteURL 解析（SPM 本地包）
├── UserContracts/       ← 用户模块协议（SPM 本地包）
├── ProductContracts/    ← 商品模块协议（SPM 本地包）
├── OrderContracts/      ← 订单模块协议（SPM 本地包）
├── UserModule/          ← 用户业务实现（SPM 本地包）
├── ProductModule/       ← 商品业务实现（SPM 本地包）
├── OrderModule/         ← 订单业务实现（SPM 本地包）
├── DESIGN.md            ← 设计文档
└── README.md
```

## 构建

```bash
# 命令行构建
xcodebuild -scheme Navigation -destination 'generic/platform=iOS Simulator' build

# 单元测试（AppBase SPM 包）
cd AppBase && swift test
```
