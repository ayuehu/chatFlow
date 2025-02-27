import SwiftUI
import MarkdownUI

struct CardView: View {
    let item: Item
    @State private var offset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
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
                .padding(.horizontal, 24)  // 分开设置水平和垂直内边距
                .padding(.vertical, 12)    // 减少垂直内边距
                .frame(width: geometry.size.width)
                .background(Color(hex: "#F7F8FC"))
            }
            .offset(x: offset.width, y: offset.height)
        }
        .background(Color(hex: "#F7F8FC"))
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 0)
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
