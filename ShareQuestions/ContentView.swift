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

    var body: some View {
        NavigationView {
            ZStack {
                if !items.isEmpty {
                    if currentIndex >= 0 && currentIndex < shuffledIndices.count {
                        // 上一张卡片（如果有）
                        if currentIndex > 0 {
                            previousCardView?
                                .offset(x: -UIScreen.main.bounds.width + offset)
                        }
                        
                        // 当前卡片（同步加载）
//                        CardView(item: items[shuffledIndices[currentIndex]])
                        curCardView
                            .offset(x: offset)
                            .id(currentIndex) // 确保视图正确更新
                        
                        // 下一张卡片（如果有）
                        if currentIndex < shuffledIndices.count - 1 {
                            nextCardView?
                                .offset(x: UIScreen.main.bounds.width + offset)
                        }
                    }
                }
                
                // 导航按钮
                VStack {
                    // 顶部工具栏
                    HStack {
                        Spacer()
                        
                        // 退出登录按钮
                        Button {
                            showingLogoutAlert = true
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                                .padding(8)
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 4) // 增加顶部间距，避免遮挡标题
                    
                    Spacer()
                    
                    // 左右滑动按钮放在页面中间
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
                loadInitialData()
                print("数组长度-----: \(items.count)")
                print("index",currentIndex)
                loadCurCards(for: currentIndex)
            }
            .ignoresSafeArea(edges: .bottom)
            .onChange(of: currentIndex) { oldValue, newValue in
                loadCurCards(for: currentIndex)
                Task {
                    await loadAdjacentCards(for: newValue)
                }
            }
            .task {
                // 初始加载相邻卡片
                await loadAdjacentCards(for: currentIndex)
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
        items[shuffledIndices[currentIndex]].isViewed = true
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
//        purgeAllData() // 调试阶段启用
        // 只在数据为空时加载预设数据
        if items.isEmpty {
            // 获取 Bundle 中 Data 文件夹的 URL
            if let dataFolderURL = Bundle.main.url(forResource: "Data", withExtension: nil) {
                do {
                    // 获取 Data 文件夹下的所有文件
                    let fileURLs = try FileManager.default.contentsOfDirectory(
                        at: dataFolderURL,
                        includingPropertiesForKeys: nil
                    )
                    
                    // 遍历所有 .txt 文件
                    for fileURL in fileURLs where fileURL.pathExtension == "txt" {
                        // 获取文件名（不含扩展名）
                        let filename = fileURL.deletingPathExtension().lastPathComponent
                        print("正在加载文件：\(filename)")
                        
                        // 加载文件内容
                        let questions = QuestionLoader.loadQuestionsFromFile(named: filename)
                        if !questions.isEmpty {
                            for question in questions {
                                modelContext.insert(question)
                            }
                            print("成功加载 \(questions.count) 个问题")
                        }
                    }
                    saveContext()
                    print("数组长度1: \(items.count)")
                } catch {
                    print("读取文件夹失败：\(error)")
                    // 如果文件加载失败，使用预设数据
                    loadFallbackData()
                }
            } else {
                print("找不到 Data 文件夹")
                loadFallbackData()
            }
        }
        // 确保只初始化一次
        if shuffledIndices.isEmpty {
            print("开始加载未浏览的卡片")
            
            // 获取未浏览的 Item 下标
            let unviewedIndices = items.enumerated().compactMap { index, item in
                item.isViewed ? nil : index
            }
            
            print("总卡片数: \(items.count), 未浏览卡片数: \(unviewedIndices.count)")
            
            // 如果有未浏览的卡片，随机打散它们的顺序
            if !unviewedIndices.isEmpty {
                shuffledIndices = unviewedIndices.shuffled()
                currentIndex = 0
                print("已加载 \(shuffledIndices.count) 张未浏览的卡片")
            } else {
                // 如果所有卡片都已浏览过，可以选择：
                // 1. 重置所有卡片的浏览状态
                // 2. 显示完成提示
                // 3. 重新加载所有卡片
                
                // 这里选择重新加载所有卡片
                shuffledIndices = Array(0..<items.count).shuffled()
                currentIndex = 0
                
                // 重置所有卡片的浏览状态
                for index in 0..<items.count {
                    items[index].isViewed = false
                }
                saveContext()
                print("所有卡片已浏览完，重新开始")
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
        guard index >= 0 && index < shuffledIndices.count else {
            print("无效的索引: \(index)")
            return
        }
        
        let curIndex = shuffledIndices[index]
        print("加载当前卡片, index: \(curIndex), 问题: \(items[curIndex].question)")
        
        // 更新当前卡片
        curCardView = getCard(for: curIndex, item: items[curIndex])
    }
    
    private func loadAdjacentCards(for index: Int) async {
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
