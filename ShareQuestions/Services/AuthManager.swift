import Foundation
import SwiftUI
import LeanCloud
import SwiftData

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private init() {
        // 检查是否有已登录用户
        print("检查是否有已登录用户")
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        if let lcUser = AuthService.shared.getCurrentUser() {
            do {
                print("获取到当前的用户")
                if let username = lcUser.username?.value as? String,
                   let email = lcUser.email?.value as? String,
                   let objectId = lcUser.objectId?.stringValue {
                    self.currentUser = User(
                        username: username,
                        email: email,
                        objectId: objectId,
                        isLoggedIn: true
                    )
                    print("用户已经登录", username)
                    self.isAuthenticated = true
                }
            } catch {
                self.errorMessage = "获取用户信息失败: \(error.localizedDescription)"
                self.isAuthenticated = false
            }
        } else {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
    
    func login(identifier: String, password: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            try await AuthService.shared.login(identifier: identifier, password: password)
            
            // 延迟检查登录状态，给AuthService足够时间更新isAuthenticated
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            
            // 如果登录失败但没有抛出异常，确保重置加载状态
            if !self.isAuthenticated {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if self.errorMessage == nil {
                        self.errorMessage = "登录失败，请检查用户名和密码"
                    }
                }
            } else {
                // 登录成功，确保清除错误信息
                DispatchQueue.main.async {
                    self.errorMessage = nil
                    self.isLoading = false
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "登录失败，请检查用户名和密码"
                self.isLoading = false
            }
        }
    }
    
    func register(username: String, email: String, password: String) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let lcUser = try await AuthService.shared.register(username: username, email: email, password: password)
            print("register success")
            DispatchQueue.main.async {
                do {
                    if let username = try lcUser.get("username") as? String,
                       let email = try lcUser.get("email") as? String,
                       let objectId = lcUser.objectId?.stringValue {
                        self.currentUser = User(
                            username: username,
                            email: email,
                            objectId: objectId,
                            isLoggedIn: true
                        )
                        self.isAuthenticated = true
                        self.errorMessage = nil // 确保清除错误信息
                    } else {
                        self.errorMessage = "获取用户信息失败"
                    }
                    print("username", username)
                    print("email", email)
                } catch {
                    self.errorMessage = "获取用户信息失败: \(error.localizedDescription)"
                }
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "注册失败: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func logout() {
        AuthService.shared.logout()
        self.isAuthenticated = false
        self.currentUser = nil
    }
} 
