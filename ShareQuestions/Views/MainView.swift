import SwiftUI

struct MainView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                ContentView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            // 检查用户登录状态
            authManager.checkAuthStatus()
        }
    }
} 