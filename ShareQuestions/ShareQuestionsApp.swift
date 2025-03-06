//
//  ShareQuestionsApp.swift
//  ShareQuestions
//
//  Created by kaka on 2025/2/23.
//

import SwiftUI
import SwiftData
import LeanCloud

@main
struct ShareQuestionsApp: App {
    let container: ModelContainer = {
        let schema = Schema([
            Item.self,
            ChatMessage.self,  // 添加ChatMessage模型
            User.self  // 添加User模型
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        // 初始化LeanCloud SDK
        print("start init leancloud")
        setupLeanCloud()
    }
    
    private func setupLeanCloud() {
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

    var body: some Scene {
        WindowGroup {
            SplashScreenView()  // 使用新的启动屏幕
        }
        .modelContainer(container)
    }
}

// 新的启动屏幕，显示启动动画后跳转到MainView
struct SplashScreenView: View {
    @State private var isActive = false
    @State private var opacity1 = 0.0  // 第一行文字透明度
    @State private var opacity2 = 0.0  // 第二行文字透明度
    
    var body: some View {
        if isActive {
            MainView()
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
