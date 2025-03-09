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
            User.self,  // 添加User模型
            AppConfig.self  // 添加AppConfig模型
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
    @Environment(\.modelContext) private var modelContext
    @State private var preloadedData: Bool = false
    
    var body: some View {
        if isActive {
            MainView(preloadedData: preloadedData)
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
                // 开始预加载数据
                Task {
                    await preloadData()
                }
                
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
    
    // 预加载数据方法
    private func preloadData() async {
        do {
            // 获取或创建AppConfig
            let appConfig = try getOrCreateAppConfig()
            
            // 从LeanCloud获取数据版本和最大索引
            let remoteVersion = try await QuestionService.shared.fetchDataVersion()
            let maxIndex = try await QuestionService.shared.fetchMaxIndex()
            
            print("预加载 - 远程数据版本: \(remoteVersion), 本地数据版本: \(appConfig.dataVersion)")
            print("预加载 - 最大索引: \(maxIndex), 已浏览索引数量: \(appConfig.viewedIndices.count)")
            
            // 检查是否需要更新数据
            let descriptor = FetchDescriptor<Item>()
            let items = try modelContext.fetch(descriptor)
            
            if remoteVersion > appConfig.dataVersion || items.isEmpty {
                // 如果所有索引都已浏览，重置已浏览索引
                if appConfig.viewedIndices.count >= maxIndex {
                    print("预加载 - 所有内容已浏览，重置已浏览索引")
                    appConfig.resetViewedIndices()
                }
                
                // 生成随机索引列表（排除已浏览的索引）
                let randomIndices = QuestionService.shared.generateRandomIndices(
                    maxIndex: maxIndex,
                    viewedIndices: appConfig.viewedIndices,
                    count: 200
                )
                
                if randomIndices.isEmpty {
                    print("预加载 - 没有可用的未浏览索引")
                    preloadedData = false
                    return
                }
                
                print("预加载 - 生成随机索引: \(randomIndices.count)个")
                
                // 从LeanCloud获取问题数据
                let newItems = try await QuestionService.shared.fetchQuestionsByIndices(indices: randomIndices)
                
                if newItems.isEmpty {
                    print("预加载 - 未获取到新数据")
                    preloadedData = false
                    return
                }
                
                print("预加载 - 获取到新数据: \(newItems.count)条")
                
                // 清空现有数据
                try modelContext.delete(model: Item.self)
                
                // 插入新数据
                for item in newItems {
                    modelContext.insert(item)
                }
                
                // 更新数据版本
                appConfig.updateDataVersion(remoteVersion)
                
                // 保存上下文
                try modelContext.save()
                
                print("预加载 - 数据更新完成，当前数据量: \(newItems.count)")
            } else {
                print("预加载 - 无需更新数据，当前数据量: \(items.count)")
            }
            
            preloadedData = true
            
        } catch {
            print("预加载数据失败: \(error)")
            preloadedData = false
            
            // 如果从LeanCloud加载失败，尝试使用本地数据
            let descriptor = FetchDescriptor<Item>()
            do {
                let items = try modelContext.fetch(descriptor)
                if items.isEmpty {
                    loadFallbackData()
                }
            } catch {
                print("检查本地数据失败: \(error)")
                loadFallbackData()
            }
        }
    }
    
    // 获取或创建AppConfig
    private func getOrCreateAppConfig() throws -> AppConfig {
        let descriptor = FetchDescriptor<AppConfig>()
        let configs = try modelContext.fetch(descriptor)
        
        if let config = configs.first {
            return config
        } else {
            let newConfig = AppConfig()
            modelContext.insert(newConfig)
            try modelContext.save()
            return newConfig
        }
    }
    
    // 加载预设数据作为后备方案
    private func loadFallbackData() {
        for question in QuestionData.questions {
            modelContext.insert(question)
        }
        print("预加载 - 已加载预设数据")
        preloadedData = true
    }
}
