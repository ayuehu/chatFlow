//
//  ContentView.swift
//  ShareQuestions
//
//  Created by kaka on 2025/2/23.
//

import SwiftUI
import SwiftData
import Foundation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var currentIndex = 0
    @State private var offset: CGFloat = 0
    @State private var shuffledIndices: [Int] = []
    @State private var isDragging = false
    @State private var previousCardView: CardView?
    @State private var nextCardView: CardView?
    @State private var curCardView: CardView?
    @State private var cache: [Int: CardView] = [:]
    @StateObject private var authManager = AuthManager.shared
    @State private var showingLogoutAlert = false
    @State private var showingLoginSheet = false
    @State private var isLoading: Bool
    var preloadedData: Bool
    
    init(preloadedData: Bool = false) {
        self.preloadedData = preloadedData
        // 如果数据已预加载，则初始化时不显示加载状态
        _isLoading = State(initialValue: !preloadedData)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // 背景色
                Color(hex: "#F7F8FC").ignoresSafeArea()
                
                if isLoading {
                    // 加载指示器和骨架屏
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#4E4FEB")))
                        
                        Text("正在加载内容...")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#8F91A8"))
                        
                        // 骨架屏
                        SkeletonCardView()
                    }
                } else if !items.isEmpty && !shuffledIndices.isEmpty {
                    if currentIndex >= 0 && currentIndex < shuffledIndices.count {
                        // 上一张卡片（如果有）
                        if currentIndex > 0 {
                            previousCardView?
                                .offset(x: -UIScreen.main.bounds.width + offset)
                        }
                        
                        // 当前卡片（同步加载）
                        curCardView
                            .offset(x: offset)
                            .id(currentIndex) // 确保视图正确更新
                        
                        // 下一张卡片（如果有）
                        if currentIndex < shuffledIndices.count - 1 {
                            nextCardView?
                                .offset(x: UIScreen.main.bounds.width + offset)
                        }
                    }
                } else {
                    // 无数据状态
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(Color(hex: "#8F91A8"))
                        
                        Text("暂无内容")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(hex: "#585A73"))
                        
                        Button {
                            isLoading = true
                            loadInitialData()
                        } label: {
                            Text("重新加载")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color(hex: "#4E4FEB"))
                                .cornerRadius(8)
                        }
                    }
                }
                
                // 导航按钮
                VStack {
                    // 顶部工具栏
                    HStack {
                        Spacer()
                        
                        // 根据登录状态显示不同的图标
                        Button {
                            if authManager.isAuthenticated {
                                // 已登录，显示退出登录确认
                                showingLogoutAlert = true
                            } else {
                                // 未登录，显示登录页面
                                showingLoginSheet = true
                                // 清除之前的错误信息
                                authManager.errorMessage = nil
                            }
                        } label: {
                            Image(systemName: authManager.isAuthenticated ? "rectangle.portrait.and.arrow.right" : "person.circle")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .padding(8)
                                .background(Color.white.opacity(0.6))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 2) // 增加顶部间距，避免遮挡标题
                    
                    Spacer()
                    
                    // 左右滑动按钮放在页面中间
                    if !isLoading && !items.isEmpty && !shuffledIndices.isEmpty {
                        HStack {
                            // 左箭头按钮
                            Button(action: previousCard) {
                                Image(systemName: "chevron.backward.2")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                    .opacity(currentIndex > 0 ? 1 : 0.3)
                            }
                            .disabled(currentIndex == 0)
                            .frame(width: 24, height: 24)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            
                            Spacer()
                            
                            // 右箭头按钮
                            Button(action: nextCard) {
                                Image(systemName: "chevron.forward.2")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                                    .opacity(currentIndex < shuffledIndices.count - 1 ? 1 : 0.3)
                            }
                            .disabled(currentIndex >= shuffledIndices.count - 1)
                            .frame(width: 24, height: 24)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 10)
                    }
                    
                    Spacer()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        isDragging = true
                        withAnimation(.interactiveSpring()) {
                            offset = gesture.translation.width
                        }
                    }
                    .onEnded { gesture in
                        isDragging = false
                        let threshold: CGFloat = 50
                        let velocity = gesture.predictedEndLocation.x - gesture.location.x
                        let screenWidth = UIScreen.main.bounds.width
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if (gesture.translation.width < -threshold && currentIndex < shuffledIndices.count - 1) ||
                               (velocity < -500 && currentIndex < shuffledIndices.count - 1) {
                                offset = -screenWidth
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    currentIndex += 1
                                    markAsViewed()
                                    saveContext()
                                    withAnimation(.none) {
                                        offset = 0
                                    }
                                }
                            } else if (gesture.translation.width > threshold && currentIndex > 0) ||
                                      (velocity > 500 && currentIndex > 0) {
                                offset = screenWidth
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    currentIndex -= 1
                                    markAsViewed()
                                    saveContext()
                                    withAnimation(.none) {
                                        offset = 0
                                    }
                                }
                            } else {
                                offset = 0
                            }
                        }
                    }
            )
            .onAppear {
                if preloadedData {
                    // 如果数据已预加载，直接初始化卡片
                    initializeShuffledIndices()
                    loadCurCards(for: currentIndex)
                    Task {
                        await loadAdjacentCards(for: currentIndex)
                        // 确保UI更新
                        DispatchQueue.main.async {
                            isLoading = false
                        }
                    }
                } else {
                    // 否则正常加载数据
                    loadInitialData()
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .onChange(of: currentIndex) { oldValue, newValue in
                loadCurCards(for: currentIndex)
                Task {
                    await loadAdjacentCards(for: newValue)
                }
            }
            .navigationBarHidden(true)
            .alert("确认退出登录", isPresented: $showingLogoutAlert) {
                Button("取消", role: .cancel) { }
                Button("退出登录", role: .destructive) {
                    authManager.logout()
                }
            } message: {
                Text("您确定要退出登录吗？")
            }
            .sheet(isPresented: $showingLoginSheet) {
                LoginView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .onChange(of: authManager.isAuthenticated) { _, newValue in
                if newValue && showingLoginSheet {
                    // 用户登录成功，关闭登录浮层
                    showingLoginSheet = false
                }
            }
        }
    }
    
    private func previousCard() {
        let screenWidth = UIScreen.main.bounds.width
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = screenWidth
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if currentIndex > 0 {
                currentIndex -= 1
                saveContext()
                withAnimation(.none) {
                    offset = 0
                }
            }
        }
    }
    
    private func nextCard() {
        let screenWidth = UIScreen.main.bounds.width
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = -screenWidth
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if currentIndex < shuffledIndices.count - 1 {
                currentIndex += 1
                markAsViewed()
                saveContext()
                withAnimation(.none) {
                    offset = 0
                }
            }
        }
    }

    
    private func markAsViewed() {
        let item = items[shuffledIndices[currentIndex]]
        item.isViewed = true
        
        // 更新AppConfig中的已浏览索引
        do {
            let appConfig = try getOrCreateAppConfig()
            appConfig.addViewedIndex(item.index)
            try modelContext.save()
        } catch {
            print("更新已浏览索引失败: \(error)")
        }
    }
    
    // 在初始化前清空数据（仅调试使用）
    private func purgeAllData() {
        do {
            try modelContext.delete(model: Item.self)
            try modelContext.save()
            print("Successfully purged all data")
            print(items.count)
        } catch {
            print("Failed to purge data: \(error)")
        }
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("保存失败: \(error)")
        }
    }
    
    private func loadInitialData() {
        Task {
            do {
//                purgeAllData()
                // 获取或创建AppConfig
                let appConfig = try getOrCreateAppConfig()
                
                // 从LeanCloud获取数据版本和最大索引
                let remoteVersion = try await QuestionService.shared.fetchDataVersion()
                let maxIndex = try await QuestionService.shared.fetchMaxIndex()
                
                print("远程数据版本: \(remoteVersion), 本地数据版本: \(appConfig.dataVersion)")
                print("最大索引: \(maxIndex), 已浏览索引数量: \(appConfig.viewedIndices.count)")
                
                // 检查是否需要更新数据
                if remoteVersion > appConfig.dataVersion || items.isEmpty {
                    // 如果所有索引都已浏览，重置已浏览索引
                    if appConfig.viewedIndices.count >= maxIndex {
                        print("所有内容已浏览，重置已浏览索引")
                        appConfig.resetViewedIndices()
                    }
                    
                    // 生成随机索引列表（排除已浏览的索引）
                    let randomIndices = QuestionService.shared.generateRandomIndices(
                        maxIndex: maxIndex,
                        viewedIndices: appConfig.viewedIndices,
                        count: 200
                    )
                    
                    if randomIndices.isEmpty {
                        print("没有可用的未浏览索引")
                        DispatchQueue.main.async {
                            isLoading = false
                        }
                        return
                    }
                    
                    print("生成随机索引: \(randomIndices.count)个")
                    
                    // 从LeanCloud获取问题数据
                    let newItems = try await QuestionService.shared.fetchQuestionsByIndices(indices: randomIndices)
                    
                    if newItems.isEmpty {
                        print("未获取到新数据")
                        DispatchQueue.main.async {
                            isLoading = false
                        }
                        return
                    }
                    
                    print("获取到新数据: \(newItems.count)条")
                    
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
                    
                    // 重新初始化shuffledIndices
                    initializeShuffledIndices()
                    
                    print("数据更新完成，当前数据量: \(items.count)")
                } else {
                    // 如果不需要更新数据，仅初始化shuffledIndices
                    initializeShuffledIndices()
                }
                print("数组长度-----: \(items.count)")
                print("index",currentIndex)
                loadCurCards(for: currentIndex)
                await loadAdjacentCards(for: currentIndex)
                
                // 数据加载完成，关闭加载状态
                DispatchQueue.main.async {
                    isLoading = false
                }
            } catch {
                print("加载数据失败: \(error)")
                
                // 如果从LeanCloud加载失败，尝试使用本地数据
                if items.isEmpty {
                    loadFallbackData()
                    initializeShuffledIndices()
                }
                print("数组长度-----: \(items.count)")
                print("index",currentIndex)
                loadCurCards(for: currentIndex)
                await loadAdjacentCards(for: currentIndex)
                
                // 数据加载完成，关闭加载状态
                DispatchQueue.main.async {
                    isLoading = false
                }
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
    
    // 初始化shuffledIndices
    private func initializeShuffledIndices() {
        if items.isEmpty {
            shuffledIndices = []
            return
        }
        
        // 获取未浏览的Item索引
        let unviewedIndices = items.enumerated().compactMap { index, item in
            item.isViewed ? nil : index
        }
        
        print("未浏览的Item数量: \(unviewedIndices.count)")
        
        // 如果有未浏览的Item，随机打散它们的顺序
        if !unviewedIndices.isEmpty {
            shuffledIndices = unviewedIndices.shuffled()
            currentIndex = 0
        } else {
            // 如果所有Item都已浏览，尝试从数据库加载新数据
            print("所有Item已浏览完，尝试从数据库加载新数据")
            
            // 先临时使用所有索引，以防加载失败时仍有内容显示
            shuffledIndices = Array(0..<items.count).shuffled()
            currentIndex = 0
            
            // 触发从数据库加载新数据
            Task {
                await refreshDataFromServer()
            }
        }
    }
    
    // 从服务器刷新数据
    private func refreshDataFromServer() async {
        do {
            // 获取或创建AppConfig
            let appConfig = try getOrCreateAppConfig()
            
            // 从LeanCloud获取数据版本和最大索引
            let remoteVersion = try await QuestionService.shared.fetchDataVersion()
            let maxIndex = try await QuestionService.shared.fetchMaxIndex()
            
            print("刷新数据 - 远程数据版本: \(remoteVersion), 本地数据版本: \(appConfig.dataVersion)")
            
            // 生成随机索引列表
            let randomIndices = QuestionService.shared.generateRandomIndices(
                maxIndex: maxIndex,
                viewedIndices: appConfig.viewedIndices,
                count: 200
            )
            
            if randomIndices.isEmpty {
                print("刷新数据 - 没有可用的未浏览索引")
                return
            }
            
            print("刷新数据 - 生成随机索引: \(randomIndices.count)个")
            
            // 从LeanCloud获取问题数据
            let newItems = try await QuestionService.shared.fetchQuestionsByIndices(indices: randomIndices)
            
            if newItems.isEmpty {
                print("刷新数据 - 未获取到新数据")
                return
            }
            
            print("刷新数据 - 获取到新数据: \(newItems.count)条")
            
            // 在主线程中更新UI和数据
            DispatchQueue.main.async {
                do {
                    // 清空现有数据
                    try self.modelContext.delete(model: Item.self)
                    
                    // 插入新数据
                    for item in newItems {
                        self.modelContext.insert(item)
                    }
                    
                    // 更新数据版本
                    appConfig.updateDataVersion(remoteVersion)
                    
                    // 保存上下文
                    try self.modelContext.save()
                    
                    // 重新初始化shuffledIndices
                    self.initializeShuffledIndicesAfterRefresh()
                    
                    // 加载当前卡片
                    self.loadCurCards(for: self.currentIndex)
                    
                    print("刷新数据 - 数据更新完成，当前数据量: \(self.items.count)")
                } catch {
                    print("刷新数据 - 更新数据失败: \(error)")
                }
            }
        } catch {
            print("刷新数据 - 加载数据失败: \(error)")
        }
    }
    
    // 刷新数据后重新初始化shuffledIndices（避免递归调用）
    private func initializeShuffledIndicesAfterRefresh() {
        if items.isEmpty {
            shuffledIndices = []
            return
        }
        
        // 获取未浏览的Item索引
        let unviewedIndices = items.enumerated().compactMap { index, item in
            item.isViewed ? nil : index
        }
        
        print("刷新后 - 未浏览的Item数量: \(unviewedIndices.count)")
        
        // 如果有未浏览的Item，随机打散它们的顺序
        if !unviewedIndices.isEmpty {
            shuffledIndices = unviewedIndices.shuffled()
            currentIndex = 0
            
            // 异步加载相邻卡片
            Task {
                await loadAdjacentCards(for: currentIndex)
            }
        } else {
            // 如果仍然没有未浏览的Item，重置所有Item的浏览状态
            shuffledIndices = Array(0..<items.count).shuffled()
            currentIndex = 0
            
            // 重置所有Item的浏览状态
            for index in 0..<items.count {
                items[index].isViewed = false
            }
            
            try? modelContext.save()
            print("刷新后 - 所有Item仍已浏览完，重置浏览状态")
            
            // 异步加载相邻卡片
            Task {
                await loadAdjacentCards(for: currentIndex)
            }
        }
    }
    
    // 加载预设数据作为后备方案
    private func loadFallbackData() {
        for question in QuestionData.questions {
            modelContext.insert(question)
        }
        print("已加载预设数据")
    }
    
    private func getCard(for index: Int, item: Item) -> CardView {
        if let cachedCard = cache[index] {
            print("获取缓存卡片: \(item.question)")
            return cachedCard
        }
        print("创建新卡片: \(item.question)")
        let newCard = CardView(item: item)
        cache[index] = newCard
        return newCard
    }

    private func loadCurCards(for index: Int) {
        // 确保索引有效
        print("加载当前卡片")
        guard index >= 0 && index < shuffledIndices.count else {
            print("无效的索引: \(index)")
            print("shuffledIndices count:", shuffledIndices.count)
            return
        }
        
        let curIndex = shuffledIndices[index]
        print("加载当前卡片, index: \(curIndex), 问题: \(items[curIndex].question)")
        
        // 更新当前卡片
        curCardView = getCard(for: curIndex, item: items[curIndex])
    }
    
    private func loadAdjacentCards(for index: Int) async {
        print("加载相邻卡片")
        guard index >= 0 && index < shuffledIndices.count else {
            print("无效的索引: \(index)")
            return
        }
        
        // 加载上一张卡片
        if index > 0 {
            let prevIndex = shuffledIndices[index - 1]
            previousCardView = getCard(for: prevIndex, item: items[prevIndex])
            print("加载上一张卡片: \(items[prevIndex].question)")
        } else {
            previousCardView = nil
        }
        
        // 加载下一张卡片
        if index < shuffledIndices.count - 1 {
            let nextIndex = shuffledIndices[index + 1]
            nextCardView = getCard(for: nextIndex, item: items[nextIndex])
            print("加载下一张卡片: \(items[nextIndex].question)")
        } else {
            nextCardView = nil
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
