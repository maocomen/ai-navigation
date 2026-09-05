import Foundation

/// 用户仓库 - 内存态用户数据与登录会话管理
/// 未来可替换为网络 / 数据库实现
public final class UserRepository: @unchecked Sendable {
    public static let shared = UserRepository()

    /// 已注册用户（内存态）
    private var users: [User] = []

    /// 当前登录用户 ID
    private var currentUserID: String?

    private let lock = NSLock()

    private init() {}

    // MARK: - 注册 / 登录

    public enum AuthError: Error, LocalizedError, Equatable {
        case usernameTaken
        case emailTaken
        case invalidCredentials
        case notFound

        public var errorDescription: String? {
            switch self {
            case .usernameTaken: return "用户名已被占用"
            case .emailTaken: return "邮箱已被注册"
            case .invalidCredentials: return "用户名或密码错误"
            case .notFound: return "用户不存在"
            }
        }
    }

    /// 注册新用户（密码仅做演示校验，不持久化）
    @discardableResult
    public func register(username: String, email: String) throws -> User {
        lock.lock(); defer { lock.unlock() }
        guard !users.contains(where: { $0.username == username }) else {
            throw AuthError.usernameTaken
        }
        guard !users.contains(where: { $0.email == email }) else {
            throw AuthError.emailTaken
        }
        let id = "u\(users.count + 1)"
        let user = User(id: id, username: username, email: email, nickname: username)
        users.append(user)
        currentUserID = id
        return user
    }

    /// 登录（按用户名查找）
    public func login(username: String) throws -> User {
        lock.lock(); defer { lock.unlock() }
        guard let user = users.first(where: { $0.username == username }) else {
            throw AuthError.invalidCredentials
        }
        currentUserID = user.id
        return user
    }

    /// 登出
    public func logout() {
        lock.lock(); defer { lock.unlock() }
        currentUserID = nil
    }

    // MARK: - 查询 / 更新

    public var currentUser: User? {
        lock.lock(); defer { lock.unlock() }
        guard let id = currentUserID else { return nil }
        return users.first { $0.id == id }
    }

    @discardableResult
    public func updateProfile(nickname: String, bio: String) -> User? {
        lock.lock(); defer { lock.unlock() }
        guard let id = currentUserID,
              let idx = users.firstIndex(where: { $0.id == id }) else { return nil }
        users[idx].nickname = nickname
        users[idx].bio = bio
        return users[idx]
    }

    /// 更新当前用户登录时间
    public func touchLastLogin() {
        lock.lock(); defer { lock.unlock() }
        guard let id = currentUserID,
              let idx = users.firstIndex(where: { $0.id == id }) else { return }
        users[idx].lastLoginDate = Date()
    }

    // MARK: - 演示：预置一个可登录账号

    public func seedDemoUserIfNeeded() {
        lock.lock(); defer { lock.unlock() }
        guard !users.contains(where: { $0.username == "demo" }) else { return }
        users.append(User(
            id: "demo",
            username: "demo",
            email: "demo@example.com",
            nickname: "Demo User",
            bio: "这是一个演示账号",
            registerDate: Date(timeIntervalSince1970: 1735689600) // 2026-01-01
        ))
    }
}
