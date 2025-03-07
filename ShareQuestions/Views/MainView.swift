import SwiftUI

struct MainView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        // 无论登录状态如何，都直接显示ContentView
        ContentView()
            .onAppear {
                // 检查用户登录状态
                authManager.checkAuthStatus()
            }
    }
} 