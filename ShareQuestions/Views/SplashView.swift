import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var opacity1 = 0.0  // 第一行文字透明度
    @State private var opacity2 = 0.0  // 第二行文字透明度
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                Color(hex: "#F7F8FC")
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Text("提问即灵感")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(Color(hex: "#2C2C36"))
                        .opacity(opacity1)
                    
                    Text("回答见众生")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(Color(hex: "#2C2C36"))
                        .opacity(opacity2)
                }
            }
            .onAppear {
                // 第一行文字淡入
                withAnimation(.easeIn(duration: 1.0)) {
                    opacity1 = 1.0
                }
                
                // 第二行文字延迟0.5秒后淡入
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeIn(duration: 1.0)) {
                        opacity2 = 1.0
                    }
                }
                
                // 2秒后开始淡出
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        opacity1 = 0.0
                        opacity2 = 0.0
                    }
                }
                
                // 2秒后切换到主界面
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.isActive = true
                }
            }
        }
    }
} 
