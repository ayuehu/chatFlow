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
    @State private var shuffledIndices: [Int] = [] // 存储随机打散的下标
    
    var body: some View {
        NavigationView {
            ZStack {
                Text("")
                    .onAppear {
                        loadInitialData()
                        print("数组长度-----: \(items.count)")
                        print("index",currentIndex)
                    }
                if !items.isEmpty {
                    // 上一张卡片（如果有）
                    if currentIndex > 0 {
                        CardView(item: items[shuffledIndices[currentIndex - 1]])
                            .offset(x: -UIScreen.main.bounds.width + offset)
                    }
                    
                    // 当前卡片
                    if currentIndex >= 0 && currentIndex <= shuffledIndices.count - 1 {
                        CardView(item: items[shuffledIndices[currentIndex]])
                            .offset(x: offset)
                    }
                    
                    // 下一张卡片（如果有）
                    if currentIndex < shuffledIndices.count - 1 {
                        CardView(item: items[shuffledIndices[currentIndex + 1]])
                            .offset(x: UIScreen.main.bounds.width + offset)
                    }
                } else {
                    Text("加载中...")
                        .onAppear {
//                            loadInitialData()
                        }
                }
                
                // 导航按钮
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
                .padding(.horizontal, 12)
            }
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation.width
                    }
                    .onEnded { gesture in
                        let threshold: CGFloat = 50
                        let velocity = gesture.predictedEndLocation.x - gesture.location.x
                        let screenWidth = UIScreen.main.bounds.width
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if (gesture.translation.width < -threshold && currentIndex < shuffledIndices.count - 1) ||
                               (velocity < -500 && currentIndex < shuffledIndices.count - 1) {
                                offset = -screenWidth
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    currentIndex += 1
                                    markAsViewed()
                                    withAnimation(.none) {
                                        offset = 0
                                    }
                                }
                            } else if (gesture.translation.width > threshold && currentIndex > 0) ||
                                      (velocity > 500 && currentIndex > 0) {
                                offset = screenWidth
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    currentIndex -= 1
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
            .ignoresSafeArea(edges: .bottom)
        }
    }
    
    private func previousCard() {
        let screenWidth = UIScreen.main.bounds.width
        withAnimation(.easeInOut(duration: 0.3)) {
            offset = screenWidth
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if currentIndex > 0 {
                currentIndex -= 1
                withAnimation(.none) {
                    offset = 0
                }
            }
        }
    }
    
    private func nextCard() {
        let screenWidth = UIScreen.main.bounds.width
        withAnimation(.easeInOut(duration: 0.3)) {
            offset = -screenWidth
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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
//                                print("question", question.question)
//                                print("answer", question.answer)
//                                print("thinking", question.thinking)
//                                print("type", question.type)
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
        // 获取未浏览的 Item 下标
        print("数组长度: \(items.count)")
        let unviewedIndices = items.enumerated().compactMap { index, item in
            item.isViewed ? nil : index
        }
        print("unviewedIndices数组长度: \(unviewedIndices.count)")
        // 随机打散下标
        shuffledIndices = unviewedIndices.shuffled()
        print("shuffledIndices数组长度: \(unviewedIndices.count)")
        // 加载数据
        for index in shuffledIndices {
            modelContext.insert(items[index])
        }
    }
    
    // 加载预设数据作为后备方案
    private func loadFallbackData() {
        for question in QuestionData.questions {
            modelContext.insert(question)
        }
        print("已加载预设数据")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
