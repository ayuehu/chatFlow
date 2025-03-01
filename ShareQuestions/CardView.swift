import SwiftUI
import MarkdownUI
import SwiftData

struct CardView: View {
    let item: Item
    @State private var offset: CGSize = .zero
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var showChat = false
    @State private var chatMessages: [ChatMessage] = []
    @Environment(\.modelContext) private var modelContext
    
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
                        
//                    // 分割线
//                    Divider()
//                        .background(Color.gray.opacity(0.3))
//                        .padding(.vertical, 5)
                        
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
                    }
                }
            }
            .scrollIndicators(.hidden)  // 隐藏滚动条
            .offset(x: offset.width, y: offset.height)
            .overlay(alignment: .bottom) {
                ChatInputView(showChat: $showChat)
                    .padding(.bottom, 20)
            }
            .sheet(isPresented: $showChat) {
                ChatView(
                    isPresented: $showChat,
                    messages: $chatMessages,
                    currentQuestion: item.question,
                    currentAnswer: item.answer
                )
                .presentationDetents([.medium, .large])
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

struct ChatInputView: View {
    @Binding var showChat: Bool
    
    var body: some View {
        HStack {
            Text("继续聊聊这个话题")
                .font(.system(size: 18))
                .lineSpacing(10)
                .tracking(0)
                .foregroundColor(Color(hex: "#585A73"))
            Spacer()
            Image(systemName: "chevron.up")
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
        .onTapGesture {
            showChat = true
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
