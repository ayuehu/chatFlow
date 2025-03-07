import SwiftUI

struct LoginView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var authManager = AuthManager.shared
    @State private var identifier: String = ""
    @State private var password: String = ""
    @State private var isShowingRegister: Bool = false
    @FocusState private var isIdentifierFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "#F7F8FC").ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // 标题
                    VStack(spacing: 8) {
                        Text("ChatFlow")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(Color(hex: "#2C2C36"))
                    }
                    .padding(.top, 50)
                    
                    Spacer()
                    
                    // 登录表单
                    VStack(spacing: 20) {
                        // 用户名/邮箱输入框
                        VStack(alignment: .leading, spacing: 8) {
                            Text("用户名/邮箱")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "#585A73"))
                            
                            TextField("请输入用户名或邮箱", text: $identifier)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(15)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color(hex: "#E2E2EA"), lineWidth: 1)
                                )
                                .focused($isIdentifierFocused)
                        }
                        
                        // 密码输入框
                        VStack(alignment: .leading, spacing: 8) {
                            Text("密码")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "#585A73"))
                            
                            SecureField("请输入密码", text: $password)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(15)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color(hex: "#E2E2EA"), lineWidth: 1)
                                )
                        }
                        
                        // 错误信息
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(.top, 8)
                        }
                        
                        // 登录按钮
                        Button {
                            Task {
                                await authManager.login(identifier: identifier, password: password)
                                
                                // 登录成功后自动关闭浮层
                                if authManager.isAuthenticated {
                                    DispatchQueue.main.async {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                            }
                        } label: {
                            Text("登录")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#000000"))
                                .cornerRadius(10)
                        }
                        .disabled(identifier.isEmpty || password.isEmpty || authManager.isLoading)
                        .opacity(identifier.isEmpty || password.isEmpty || authManager.isLoading ? 0.6 : 1)
                        
                        // 注册链接
                        Button {
                            isShowingRegister = true
                        } label: {
                            Text("没有账号？立即注册")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "#C8CAD9"))
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
                
                // 加载指示器
                if authManager.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#4E4FEB")))
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 80, height: 80)
                        )
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isShowingRegister) {
                RegisterView()
            }
            .onAppear {
                // 自动聚焦到用户名/邮箱输入框
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isIdentifierFocused = true
                }
            }
            // 监听登录状态变化
            .onChange(of: authManager.isAuthenticated) { _, newValue in
                if newValue {
                    // 登录成功，关闭浮层
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

//// 颜色扩展（如果项目中已有，可以删除此部分）
//extension Color {
//    init(hex: String) {
//        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
//        var int: UInt64 = 0
//        Scanner(string: hex).scanHexInt64(&int)
//        let a, r, g, b: UInt64
//        switch hex.count {
//        case 3: // RGB (12-bit)
//            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
//        case 6: // RGB (24-bit)
//            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
//        case 8: // ARGB (32-bit)
//            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
//        default:
//            (a, r, g, b) = (1, 1, 1, 0)
//        }
//        
//        self.init(
//            .sRGB,
//            red: Double(r) / 255,
//            green: Double(g) / 255,
//            blue:  Double(b) / 255,
//            opacity: Double(a) / 255
//        )
//    }
//} 
