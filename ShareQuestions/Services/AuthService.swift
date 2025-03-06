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
        
        
        // 保存用户
        _ = user.signUp { (result) in
               switch result {
               case .success:
                   print("新用户注册成功")
                   break
               case .failure(error: let error):
                   print(error)
               }
           }
        return user
    }
    
    // 用户登录
    func login(identifier: String, password: String) async throws {
        // 判断是邮箱还是用户名登录
        let isEmail = identifier.contains("@")
        
        let hashedPassword = hashPassword(password)
        
        if isEmail {
            // 邮箱登录
            _ = LCUser.logIn(email: identifier, password: hashedPassword) { result in
                switch result {
                case .success(let user):
                    print(user)
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
                            }
                        } catch {
                            AuthManager.shared.errorMessage = "获取用户信息失败: \(error.localizedDescription)"
                        }
                        AuthManager.shared.isLoading = false
                    }
                case .failure(error: let error):
                    DispatchQueue.main.async {
                        print(error)
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
                            }
                        } catch {
                            AuthManager.shared.errorMessage = "获取用户信息失败: \(error.localizedDescription)"
                        }
                        AuthManager.shared.isLoading = false
                    }
                case .failure(error: let error):
                    DispatchQueue.main.async {
                        print(error)
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
} 
