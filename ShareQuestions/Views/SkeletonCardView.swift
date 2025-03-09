import SwiftUI

struct SkeletonCardView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 问题部分骨架
            SkeletonRectangle(width: 300, height: 30)
            
            // 类型和字数信息骨架
            HStack(spacing: 8) {
                SkeletonRectangle(width: 80, height: 16)
                SkeletonRectangle(width: 60, height: 16)
                SkeletonRectangle(width: 40, height: 16)
            }
            
            // 答案部分骨架
            VStack(alignment: .leading, spacing: 8) {
                SkeletonRectangle(width: 350, height: 16)
                SkeletonRectangle(width: 320, height: 16)
                SkeletonRectangle(width: 340, height: 16)
                SkeletonRectangle(width: 300, height: 16)
                SkeletonRectangle(width: 330, height: 16)
                SkeletonRectangle(width: 280, height: 16)
                SkeletonRectangle(width: 350, height: 16)
                SkeletonRectangle(width: 310, height: 16)
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}

struct SkeletonRectangle: View {
    var width: CGFloat
    var height: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.3), Color.gray.opacity(0.2)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .white, .clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? width : -width)
            )
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
} 