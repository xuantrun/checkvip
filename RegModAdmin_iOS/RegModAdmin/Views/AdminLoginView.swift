import SwiftUI

public struct AdminLoginView: View {
    @ObservedObject private var theme = ThemeManager.shared
    @ObservedObject var api = AdminAPIService.shared
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var errorMessage: String? = nil
    
    public init() {}
    
    public var body: some View {
        ZStack {
            theme.backgroundColor
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 26) {
                    Spacer().frame(height: 30)
                    
                    // Header Artwork
                    VStack(spacing: 22) {
                        Image("game_cover_fft")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.red.opacity(0.8), Color.orange.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2.5
                                    )
                            )
                            .shadow(color: Color.red.opacity(0.4), radius: 16, y: 8)
                        
                        VStack(spacing: 6) {
                            Text("Chào mừng, Admin")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundColor(theme.primaryText)
                            
                            Text("Quản lý tài khoản và hoạt động trong một nơi.")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        // Status badge
                        HStack(spacing: 6) {
                            Circle()
                                .fill(api.isOnline ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(api.isOnline ? "Máy Chủ : Sẵn Sàng" : "Máy Chủ : Ngoại Tuyến")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(api.isOnline ? .green : .red)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(theme.primaryText.opacity(0.06))
                        .clipShape(Capsule())
                    }
                    
                    // Card Login
                    VStack(spacing: 20) {
                        StudioFloatingField(title: "Mật khẩu quản trị", icon: "lock.shield", text: $password, secure: true)
                            .disabled(api.isLoading)
                            .onSubmit(performLogin)

                        if let err = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(err)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding(12)
                            .background(Color.red.opacity(0.12))
                            .cornerRadius(10)
                        }
                        
                        Button(action: performLogin) {
                            HStack {
                                if api.isLoading {
                                    ProgressView().tint(.white).padding(.trailing, 4)
                                }
                                Text(api.isLoading ? "Đang xác thực…" : "Vào trang quản trị")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(theme.onAccent)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                LinearGradient(
                                    colors: [theme.accentColor, theme.accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                            .shadow(color: theme.accentColor.opacity(0.1), radius: 10, y: 4)
                        }
                        .disabled(api.isLoading || password.isEmpty)
                        

                    }
                    .padding(20)
                    .background(theme.cardBackground)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(theme.primaryText.opacity(0.08), lineWidth: 1))
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
        }
        .accentColor(theme.accentColor)
    }
    
    private func performLogin() {
        guard !api.isLoading, !password.isEmpty else { return }
        errorMessage = nil
        api.login(password: password) { success, err in
            if !success {
                errorMessage = err ?? "Đăng nhập thất bại"
            }
        }
    }
}


struct StudioFloatingField: View {
    let title: String
    let icon: String
    @Binding var text: String
    var secure = false
    @State private var revealed = false
    @FocusState private var focused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var raised: Bool { focused || !text.isEmpty }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(focused ? Color.accentColor : .secondary)
                .frame(width: 22)
            ZStack(alignment: .leading) {
                Text(title)
                    .font(raised ? .caption : .body)
                    .foregroundColor(focused ? Color.accentColor : .secondary)
                    .offset(y: raised ? -13 : 0)
                    .allowsHitTesting(false)
                Group {
                    if secure && !revealed {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                    }
                }
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .textContentType(secure ? .password : .username)
                .focused($focused)
                .accessibilityLabel(title)
                .offset(y: raised ? 8 : 0)
            }
            if secure {
                Button {
                    revealed.toggle()
                    focused = true
                } label: {
                    Image(systemName: revealed ? "eye.slash" : "eye")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(revealed ? "Ẩn mật khẩu" : "Hiện mật khẩu")
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 66)
        .background(Color.primary.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24)
            .stroke(focused ? Color.accentColor : Color.primary.opacity(0.12), lineWidth: focused ? 1.5 : 1))
        .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: raised)
    }
}
