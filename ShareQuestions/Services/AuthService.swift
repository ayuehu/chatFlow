import Foundation
import LeanCloud
import CryptoKit

class AuthService {
    static let shared = AuthService()
    
    private init() {
        // 初始化LeanCloud SDK
        do {
            try LCApplication.default.set(
                id: "cbHyiPLWFbJl1nN1tAlo5m4r-gzGzoHsz",
                key: "mjNVQ5TR0au91ddQpfU6EFjl",
                serverURL: "https://cbhyiplw.lc-cn-n1-shared.com"
            )
        } catch {
            print("LeanCloud初始化失败: \(error)")
        }
    }
    
    // 注册新用户
    func register(username: String, email: String, password: String) async throws -> LCUser {
        let user = LCUser()
        
        // 设置用户属性
        try user.set("username", value: username)
        try user.set("email", value: email)
        
        // 密码加密
        let hashedPassword = hashPassword(password)
        try user.set("password", value: hashedPassword)
        
        return try await withCheckedThrowingContinuation { continuation in
            // 保存用户
            _ = user.signUp { (result) in
                switch result {
                case .success:
                    print("新用户注册成功")
                    
                    // 注册成功后自动登录
                    _ = LCUser.logIn(username: username, password: hashedPassword) { loginResult in
                        switch loginResult {
                        case .success(let loggedInUser):
                            print("注册后自动登录成功")
                            continuation.resume(returning: loggedInUser)
                        case .failure(let error):
                            print("注册后自动登录失败: \(error)")
                            // 即使自动登录失败，也返回注册成功的用户
                            continuation.resume(returning: user)
                        }
                    }
                case .failure(error: let error):
                    print("注册失败: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // 用户登录
    func login(identifier: String, password: String) async throws {
        // 判断是邮箱还是用户名登录
        let isEmail = identifier.contains("@")
        
        let hashedPassword = hashPassword(password)
        
        return try await withCheckedThrowingContinuation { continuation in
            if isEmail {
                // 邮箱登录
                _ = LCUser.logIn(email: identifier, password: hashedPassword) { result in
                    switch result {
                    case .success(let user):
                        DispatchQueue.main.async {
                            do {
                                print("enter read user")
                                if let username = user.username?.value as? String,
                                   let email = user.email?.value as? String,
                                   let objectId = user.objectId?.stringValue {
                                    AuthManager.shared.currentUser = User(
                                        username: username,
                                        email: email,
                                        objectId: objectId,
                                        isLoggedIn: true
                                    )
                                    print("用户登录成功", username)
                                    AuthManager.shared.isAuthenticated = true
                                    AuthManager.shared.isLoading = false
                                    continuation.resume(returning: ())
                                } else {
                                    AuthManager.shared.errorMessage = "获取用户信息失败"
                                    AuthManager.shared.isLoading = false
                                    continuation.resume(throwing: NSError(domain: "AuthService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "获取用户信息失败"]))
                                }
                            } catch {
                                AuthManager.shared.errorMessage = "登录失败，请检查用户名和密码"
                                AuthManager.shared.isLoading = false
                                continuation.resume(throwing: error)
                            }
                        }
                    case .failure(error: let error):
                        DispatchQueue.main.async {
                            print(error)
                            AuthManager.shared.errorMessage = "登录失败，请检查用户名和密码"
                            AuthManager.shared.isLoading = false
                            continuation.resume(throwing: error)
                        }
                    }
                }
            } else {
                // 用户名登录
                _ = LCUser.logIn(username: identifier, password: hashedPassword) { result in
                    switch result {
                    case .success(object: let user):
                        DispatchQueue.main.async {
                            do {
                                print("enter read user")
                                if let username = user.username?.value as? String,
                                   let email = user.email?.value as? String,
                                   let objectId = user.objectId?.stringValue {
                                    AuthManager.shared.currentUser = User(
                                        username: username,
                                        email: email,
                                        objectId: objectId,
                                        isLoggedIn: true
                                    )
                                    print("用户登录成功", username)
                                    AuthManager.shared.isAuthenticated = true
                                    AuthManager.shared.isLoading = false
                                    continuation.resume(returning: ())
                                } else {
                                    AuthManager.shared.errorMessage = "获取用户信息失败"
                                    AuthManager.shared.isLoading = false
                                    continuation.resume(throwing: NSError(domain: "AuthService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "获取用户信息失败"]))
                                }
                            } catch {
                                AuthManager.shared.errorMessage = "登录失败，请检查用户名和密码"
                                AuthManager.shared.isLoading = false
                                continuation.resume(throwing: error)
                            }
                        }
                    case .failure(error: let error):
                        DispatchQueue.main.async {
                            print(error)
                            AuthManager.shared.errorMessage = "登录失败，请检查用户名和密码"
                            AuthManager.shared.isLoading = false
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        }
    }
    
    // 退出登录
    func logout() {
        LCUser.logOut()
    }
    
    // 获取当前登录用户
    func getCurrentUser() -> LCUser? {
        return LCApplication.default.currentUser
    }
    
    // 检查用户是否已登录
    func isLoggedIn() -> Bool {
        return LCApplication.default.currentUser != nil
    }
    
    // 密码加密
    private func hashPassword(_ password: String) -> String {
        let inputData = Data(password.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // 注销账号（从数据库中删除用户）
    func deleteAccount() async throws {
        // 确保有当前登录用户
        guard let currentUser = LCApplication.default.currentUser else {
            throw NSError(domain: "AuthService", code: 1002, userInfo: [NSLocalizedDescriptionKey: "没有登录用户"])
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            currentUser.delete { result in
                switch result {
                case .success:
                    print("用户账号已成功注销")
                    continuation.resume(returning: ())
                case .failure(let error):
                    print("注销账号失败: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
} 
