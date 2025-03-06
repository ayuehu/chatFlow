import SwiftUI
import MarkdownUI
import SwiftData
import UIKit
import Observation

struct CardView: View {
    @Bindable var item: Item
    @State private var offset: CGSize = .zero
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var showChat = false
    @State private var chatMessages: [ChatMessage] = []
    @Environment(\.modelContext) private var modelContext
    @State private var showLikeAnimation: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ScrollViewReader { proxy in
                    VStack(alignment: .leading, spacing: 12) {
                        // 添加一个 ID 为顶部的空 View
                        Color.clear
                            .frame(height: 0)
                            .id("top")
                        
                        // 问题部分
                        Text(item.question)
                            .font(.system(size: 21, weight: .semibold, design: .rounded))
                            .lineSpacing(10)
                            .tracking(0)
                            .foregroundColor(Color(hex: "#2C2C36"))
                            .padding(.top, 8)  // 减少顶部间距
                            .padding(.bottom, 5)
                        
                        // 类型和字数信息
                        HStack(spacing: 8) {
                            Text("@DeepSeek")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#8F91A8"))
                                .tracking(0.2)
                                .lineSpacing(7)
                            
                            Text(" | ")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#8F91A8"))
                            
                            if !item.type.isEmpty {
                                Text("# \(item.type)")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(hex: "#8F91A8"))
                                    .tracking(0.2)
                                    .lineSpacing(7)
                            }
                            
                            Text(" | ")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#8F91A8"))
                            
                            Text("\(item.answer.count)字")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#8F91A8"))
                                .tracking(0.2)
                                .lineSpacing(7)
                        }
                        .padding(.bottom, 5)
                        
                        // 答案部分
                        item.markdownContent
                            .textSelection(.enabled)
                    }
                    .padding(.horizontal, 30)  // 分开设置水平和垂直内边距
                    .padding(.vertical, 15)    // 减少垂直内边距
                    .frame(width: geometry.size.width)
                    .background(Color(hex: "#F7F8FC"))
                    .onAppear {
                        scrollProxy = proxy
                        // 在卡片出现时滚动到顶部
                        withAnimation(.none) {
                            proxy.scrollTo("top", anchor: .top)
                        }
                        // 加载聊天历史记录
                        loadChatHistory()
                    }
                }
            }
            .scrollIndicators(.hidden)  // 隐藏滚动条
            .offset(x: offset.width, y: offset.height)
//            .safeAreaInset(bottom: 80) // 为底部工具栏预留空间
            .overlay(alignment: .bottom) {
                // 底部工具栏
                HStack(spacing: 12) {
                    // 聊天输入框
                    Button {
                        showChat = true
                    } label: {
                        HStack(spacing: 14) {
                            Text("继续聊这个话题")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "#8F91A8"))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.up")
                                .foregroundColor(Color(hex: "#585A73"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(height: 46)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(
                            color: Color.black.opacity(0.02),
                            radius: 2,
                            x: 0,
                            y: 2
                        )
                    }
                    .frame(width: geometry.size.width * 0.6)
                    
                    // 点赞按钮
                    Button {
                        toggleLike()
                    } label: {
                        ZStack {
                            Capsule()
                                .fill(Color.white)
                                .frame(width: 46, height: 46)
                                .shadow(
                                    color: Color.black.opacity(0.05),
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                            
                            // 主爱心图标
                            Image(systemName: item.isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 22))
                                .foregroundColor(item.isLiked ? Color(hex: "#4E4FEB") : Color(hex: "#8F91A8"))
                                .scaleEffect(showLikeAnimation ? 1.3 : 1.0)
                                .animation(showLikeAnimation ? 
                                          Animation.spring(response: 0.3, dampingFraction: 0.6).repeatCount(1, autoreverses: true) : 
                                          .default, 
                                          value: showLikeAnimation)
                            
                            // 点赞动画
                            if showLikeAnimation {
                                ZStack {
                                    // 白色星星向上漂浮动画
                                    ForEach(0..<12) { i in
                                        Image(systemName: "star.fill")
                                            .font(.system(size: CGFloat.random(in: 8...14)))
                                            .foregroundColor(.white)
                                            .offset(
                                                x: CGFloat.random(in: -30...30),
                                                y: CGFloat.random(in: -60...0)
                                            )
                                            .rotationEffect(.degrees(Double.random(in: 0...360)))
                                            .opacity(Double.random(in: 0.5...1.0))
                                            .animation(
                                                Animation.easeOut(duration: 1.0)
                                                    .delay(Double.random(in: 0...0.3))
                                                    .speed(Double.random(in: 0.7...1.3)),
                                                value: showLikeAnimation
                                            )
                                    }
                                    
                                    // 小爱心向上漂浮动画
                                    ForEach(0..<5) { i in
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: CGFloat.random(in: 6...10)))
                                            .foregroundColor(Color(hex: "#4E4FEB").opacity(0.8))
                                            .offset(
                                                x: CGFloat.random(in: -20...20),
                                                y: CGFloat.random(in: -50...0)
                                            )
                                            .rotationEffect(.degrees(Double.random(in: -30...30)))
                                            .opacity(Double.random(in: 0.6...1.0))
                                            .animation(
                                                Animation.easeOut(duration: 1.2)
                                                    .delay(Double.random(in: 0...0.2))
                                                    .speed(Double.random(in: 0.8...1.2)),
                                                value: showLikeAnimation
                                            )
                                    }
                                }
                                .opacity(showLikeAnimation ? 1 : 0)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .sheet(isPresented: $showChat) {
                ChatView(
                    isPresented: $showChat,
                    messages: $chatMessages,
                    currentQuestion: item.question,
                    currentAnswer: item.answer
                )
                .presentationDetents([.fraction(0.75), .large])
                .presentationDragIndicator(.visible)
                .onDisappear {
                    // 在聊天窗口关闭时保存聊天记录
                    saveChatHistory()
                }
            }
        }
        .background(Color(hex: "#F7F8FC"))
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 0)
        }
    }
    
    // 切换点赞状态
    private func toggleLike() {
        // 添加触感反馈
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        
        // 直接修改item的isLiked属性
        item.isLiked.toggle()
        
        // 保存点赞状态
        do {
            try modelContext.save()
            print("点赞状态已保存")
        } catch {
            print("保存点赞状态失败: \(error)")
        }
        
        // 如果是点赞操作，显示动画
        if item.isLiked {
            showLikeAnimation = true
            
            // 1.5秒后隐藏动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showLikeAnimation = false
            }
        }
    }
    
    private func loadChatHistory() {
        let questionString = item.question
        print("正在加载问题的聊天记录: \(questionString)")
        
        let predicate = #Predicate<ChatMessage> { message in
            message.relatedQuestion == questionString
        }
        
        let descriptor = FetchDescriptor<ChatMessage>(
            predicate: predicate,
            sortBy: [SortDescriptor<ChatMessage>(\.timestamp, order: .forward)]
        )
        
        do {
            chatMessages = try modelContext.fetch(descriptor)
            print("当前卡片[\(questionString)]加载到 \(chatMessages.count) 条聊天记录")
        } catch {
            print("加载聊天记录失败: \(error)")
            chatMessages = []
        }
    }
    
    private func saveChatHistory() {
        do {
            try modelContext.save()
            print("保存聊天记录成功，当前消息数: \(chatMessages.count)")
        } catch {
            print("保存聊天记录失败: \(error)")
        }
    }
}

// 预览支持
struct MarkdownTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textCase(nil)
            .foregroundColor(.primary)
    }
}

extension Text {
    func markdownStyle() -> some View {
        self.modifier(MarkdownTextStyle())
    }
}

// 添加 Color 扩展以支持十六进制颜色
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 
