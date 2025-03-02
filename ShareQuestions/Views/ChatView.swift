import SwiftUI
import SwiftData
import MarkdownUI

struct ChatView: View {
    @Binding var isPresented: Bool
    @Binding var messages: [ChatMessage]
    @State private var newMessage = ""
    @State private var isLoading = false
    @FocusState private var isInputFocused: Bool
    let currentQuestion: String
    let currentAnswer: String
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("针对当前内容，你想问我点什么？")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#585A73"))
                Spacer()
                Button(action: {
                    isInputFocused = false
                    isPresented = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#8F91A8"))
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 12)
            .background(Color(.systemBackground))
            
            // 消息列表
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: messages.last?.content) { _ in
                    scrollToBottom(proxy: proxy)
                }
            }
            
            // 输入区域
            GeometryReader { geometry in
                HStack(spacing: 12) {
                    TextField("继续聊这个话题", text: $newMessage, axis: .vertical)
                        .focused($isInputFocused)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#8F91A8"))
                        .padding(.vertical, 8)
                    
                    if !newMessage.isEmpty {
                        Button(action: {
                            sendMessage()
                            isInputFocused = false // 发送后收起键盘
                        }) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                                .frame(width: 30, height: 30)
                                .background(isLoading ? Color.gray : Color.blue)
                                .clipShape(Circle())
                        }
                        .disabled(isLoading)
                    }
                }
                .padding(.horizontal, 16)
                .frame(width: geometry.size.width * 0.9, height: 46)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(
                    color: Color.black.opacity(0.02),
                    radius: 2,
                    x: 0,
                    y: 2
                )
                .shadow(
                    color: Color.black.opacity(0.02),
                    radius: 2,
                    x: 0,
                    y: -1
                )
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.97)
            }
            .frame(height: 60)
            .padding(.bottom)
        }
        .background(Color(.systemBackground))
        .presentationDetents([.fraction(0.67), .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(30)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFocused = true
            }
        }
    }
    
    private func MessageBubble(message: ChatMessage) -> some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.content)
                    .padding()
                    .background(Color(hex: "#EDEDF3"))
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                ScrollView {  // 添加 ScrollView 确保内容可以滚动
                    Markdown(message.content)
                        .markdownTheme(theme)
                        .lineSpacing(9)
                        .kerning(0.2)
                        .fixedSize(horizontal: false, vertical: true)
//                        .frame(maxWidth: .infinity, alignment: .leading)  // 确保文本可以占满宽度
                }
                .padding()
                .background(Color(.white))
                .foregroundColor(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                Spacer()
            }
        }
    }
    
    // Markdown 主题
    var theme: Theme {
        Theme()
            .text {
                FontFamily(.system())  // PingFang SC 使用系统字体
                FontSize(.em(0.9375))  // 15px
                FontWeight(.regular)    // normal
                ForegroundColor(Color(hex: "#585A73"))
            }
            .heading1 { configuration in
                VStack(alignment: .leading, spacing: 8) {
                    configuration.label
                        .fontWeight(.bold)
                        .font(.system(size: 28))
                    Divider()
                }
            }
            .heading2 { configuration in
                configuration.label
                    .fontWeight(.bold)
                    .font(.system(size: 24))
            }
            .heading3 { configuration in
                configuration.label
                    .fontWeight(.bold)
                    .font(.system(size: 20))
            }
            .strong {
                FontWeight(.bold)
                FontFamily(.system())
                ForegroundColor(Color(hex: "#585A73"))
            }
            .link {
                ForegroundColor(.blue)
            }
//            .listItem { configuration in
//                HStack(alignment: .firstTextBaseline) {
//                    Text("•").foregroundColor(.secondary)
//                    configuration.label
//                }
//            }
            .codeBlock { configuration in
                configuration.label
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
            .paragraph { configuration in
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)  // 允许多行
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)  // 确保文本可以占满宽度
            }
            .blockquote { configuration in
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                    .padding(.leading, 16)
            }
            .table { configuration in
                VStack(alignment: .leading, spacing: 8) {
                    configuration.label
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                        .padding(.vertical, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .tableCell { configuration in
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(nil)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
            }
    }
    
    private func sendMessage() {
        guard !newMessage.isEmpty else { return }
        
        let userMessage = ChatMessage(
            content: newMessage,
            isUser: true,
            relatedQuestion: currentQuestion
        )
        messages.append(userMessage)
        newMessage = ""
        
        let systemMessage = ChatMessage(
            content: "",
            isUser: false,
            relatedQuestion: currentQuestion
        )
        messages.append(systemMessage)
        let systemMessageIndex = messages.count - 1
        
        // 获取当前卡片的问题和答案
        let question = currentQuestion
        let answer = currentAnswer
        
        print("currentQuestion:", currentQuestion)
        
        // 构建消息历史
        let history = messages.filter { $0.id != systemMessage.id }
        let messagesToSend = DeepSeekService.shared.buildMessages(
            question: question,
            answer: answer,
            history: history
        )
        
        Task {
            do {
                try await DeepSeekService.shared.streamMessage(
                    messages: messagesToSend
                ) { chunk in
                    DispatchQueue.main.async {
                        messages[systemMessageIndex].content = chunk
                        saveChatHistory()
                    }
                }
                DispatchQueue.main.async {
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    messages[systemMessageIndex].content = "请求失败：\(error.localizedDescription)"
                    isLoading = false
                    saveChatHistory()
                }
            }
        }
        print("history message length", history.count)
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard !messages.isEmpty else { return }
        let lastID = messages[messages.count - 1].id
        withAnimation {
            proxy.scrollTo(lastID, anchor: .bottom)
        }
    }
    
    private func saveChatHistory() {
        do {
            try modelContext.save()
//            print("保存 \(messages.count) 条记录")
        } catch {
            print("保存失败: \(error)")
        }
    }
} 
