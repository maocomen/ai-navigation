import Foundation

/// 用户域对外链接常量（单一真相源）
///
/// 所有跨模块跳转（跳登录/注册/个人中心等）均引用此处常量。
public enum UserLinks {
    public static let login = "user/login"
    public static let register = "user/register"
    public static let profile = "user/profile"
    public static let settings = "user/settings"
}
