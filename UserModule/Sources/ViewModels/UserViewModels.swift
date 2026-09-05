import Foundation
import SwiftUI

// MARK: - 登录 ViewModel

@Observable
@MainActor
public final class LoginViewModel {
    public var username = ""
    public var password = ""
    public var errorMessage: String?
    public var isSubmitting = false

    private let repository: UserRepository

    public init(repository: UserRepository = .shared) {
        self.repository = repository
    }

    public var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty
            && !password.isEmpty
            && !isSubmitting
    }

    /// 登录成功返回用户，失败返回 nil 并写入 errorMessage
    public func submit() async -> Bool {
        isSubmitting = true
        defer { isSubmitting = false }
        errorMessage = nil
        do {
            let _ = try repository.login(username: username)
            repository.touchLastLogin()
            return true
        } catch let error as UserRepository.AuthError {
            errorMessage = error.localizedDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

// MARK: - 注册 ViewModel

@Observable
@MainActor
public final class RegisterViewModel {
    public var username = ""
    public var email = ""
    public var password = ""
    public var confirmPassword = ""
    public var errorMessage: String?

    private let repository: UserRepository

    public init(repository: UserRepository = .shared) {
        self.repository = repository
    }

    public var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }

    public var isPasswordValid: Bool {
        !password.isEmpty && password == confirmPassword && password.count >= 6
    }

    public var canSubmit: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty
            && isEmailValid
            && isPasswordValid
    }

    /// 注册成功返回用户
    @discardableResult
    public func submit() async -> User? {
        errorMessage = nil
        do {
            return try repository.register(username: username, email: email)
        } catch let error as UserRepository.AuthError {
            errorMessage = error.localizedDescription
            return nil
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}

// MARK: - 个人资料 ViewModel

@Observable
@MainActor
public final class ProfileViewModel {
    public var userID: String
    public var nickname: String
    public var bio: String
    public var isEditing = false
    public var saveMessage: String?

    private let repository: UserRepository

    public init(userID: String, repository: UserRepository = .shared) {
        self.userID = userID
        self.repository = repository
        if let user = repository.currentUser, user.id == userID {
            self.nickname = user.nickname
            self.bio = user.bio
        } else {
            self.nickname = userID
            self.bio = ""
        }
    }

    public var user: User? {
        repository.currentUser
    }

    public var isCurrentUser: Bool {
        repository.currentUser?.id == userID
    }

    public func beginEditing() {
        if let user = repository.currentUser, user.id == userID {
            nickname = user.nickname
            bio = user.bio
        }
        isEditing = true
    }

    public func save() {
        repository.updateProfile(nickname: nickname, bio: bio)
        isEditing = false
        saveMessage = "资料已保存"
    }

    public func logout() {
        repository.logout()
    }
}
