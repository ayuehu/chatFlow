import SwiftUI

struct MainView: View {
    @StateObject private var authManager = AuthManager.shared
    var preloadedData: Bool
    
    init(preloadedData: Bool = false) {
        self.preloadedData = preloadedData
    }
    
    var body: some View {
        // 无论登录状态如何，都直接显示ContentView
        ContentView(preloadedData: preloadedData)
            .onAppear {
                // 检查用户登录状态
                authManager.checkAuthStatus()
            }
    }
} 