import SwiftUI

struct RegisterView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var authManager = AuthManager.shared
    
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var localErrorMessage: String?
    @FocusState private var isUsernameFocused: Bool
    
    var body: some View {
        ZStack {
            Color(hex: "#F7F8FC").ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 标题
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Color(hex: "#2C2C36"))
                    }
                    
                    Spacer()
                    
                    Text("注册账号")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#2C2C36"))
                    
                    Spacer()
                    
                    // 占位，保持标题居中
                    Image(systemName: "arrow.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.clear)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // 注册表单
                ScrollView {
                    VStack(spacing: 20) {
                        // 用户名输入框
                        VStack(alignment: .leading, spacing: 8) {
                            Text("用户名")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "#585A73"))
                            
                            TextField("请输入用户名", text: $username)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(hex: "#E2E2EA"), lineWidth: 1)
                                )
                                .focused($isUsernameFocused)
                        }
                        
                        // 邮箱输入框
                        VStack(alignment: .leading, spacing: 8) {
                            Text("邮箱")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "#585A73"))
                            
                            TextField("请输入邮箱", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(hex: "#E2E2EA"), lineWidth: 1)
                                )
                        }
                        
                        // 密码输入框
                        VStack(alignment: .leading, spacing: 8) {
                            Text("密码")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "#585A73"))
                            
                            SecureField("请输入密码", text: $password)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(hex: "#E2E2EA"), lineWidth: 1)
                                )
                        }
                        
                        // 确认密码输入框
                        VStack(alignment: .leading, spacing: 8) {
                            Text("确认密码")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "#585A73"))
                            
                            SecureField("请再次输入密码", text: $confirmPassword)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(hex: "#E2E2EA"), lineWidth: 1)
                                )
                        }
                        
                        // 错误信息
                        if let errorMessage = localErrorMessage ?? authManager.errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(.top, 8)
                        }
                        
                        // 注册按钮
                        Button {
                            validateAndRegister()
                        } label: {
                            Text("注册")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#407FFD"))
                                .cornerRadius(10)
                        }
                        .disabled(username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || authManager.isLoading)
                        .opacity(username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || authManager.isLoading ? 0.6 : 1)
                        
                        // 返回登录
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Text("已有账号？返回登录")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "#407FFD"))
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
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
        .onAppear {
            // 自动聚焦到用户名输入框
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isUsernameFocused = true
            }
        }
    }
    
    private func validateAndRegister() {
        // 重置错误信息
        localErrorMessage = nil
        
        // 验证用户名
        if username.count < 3 {
            localErrorMessage = "用户名至少需要3个字符"
            return
        }
        
        // 验证邮箱
        if !isValidEmail(email) {
            localErrorMessage = "请输入有效的邮箱地址"
            return
        }
        
        // 验证密码
        if password.count < 6 {
            localErrorMessage = "密码至少需要6个字符"
            return
        }
        
        // 验证确认密码
        if password != confirmPassword {
            localErrorMessage = "两次输入的密码不一致"
            return
        }
        
        // 执行注册
        Task {
            await authManager.register(username: username, email: email, password: password)
            
            // 注册成功后，自动返回登录页面
            DispatchQueue.main.async {
                if authManager.errorMessage == nil {
                    // 显示成功提示
                    localErrorMessage = "注册成功，请登录"
                    
                    // 延迟一秒后返回登录页面
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // 验证邮箱格式
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
} 
