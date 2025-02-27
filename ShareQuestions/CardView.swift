import SwiftUI
import MarkdownUI

struct CardView: View {
    let item: Item
    @State private var offset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(item.question)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)
                    
                    item.markdownContent
                        .textSelection(.enabled)
                }
                .padding(24)
                .frame(width: geometry.size.width)
                .background(Color(.systemBackground))
            }
            .offset(x: offset.width, y: offset.height)
        }
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