import Foundation

/// 用户模型
public struct User: Identifiable, Equatable, Sendable {
    public let id: String
    public var username: String
    public var email: String
    public var nickname: String
    public var bio: String
    public var registerDate: Date
    public var lastLoginDate: Date?

    public init(
        id: String,
        username: String,
        email: String,
        nickname: String = "",
        bio: String = "",
        registerDate: Date = Date(),
        lastLoginDate: Date? = nil
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.nickname = nickname
        self.bio = bio
        self.registerDate = registerDate
        self.lastLoginDate = lastLoginDate
    }

    public var displayName: String {
        nickname.isEmpty ? username : nickname
    }
}
