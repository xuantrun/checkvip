import SwiftUI

public struct LoginView: View {
    @ObservedObject var api = APIService.shared
    @ObservedObject var loc = LocalizationManager.shared
    @ObservedObject var theme = ThemeManager.shared
    
    @State private var isRegisterMode: Bool = false
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successMessage: String? = nil
    @State private var copiedHwid: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            theme.backgroundColor
                .ignoresSafeArea()
                .onTapGesture {
                    APIService.hideKeyboard()
                }
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // MARK: - Header Logo & Title
                    VStack(spacing: 14) {
                        if let uiImg = UIImage(named: "doraemon") ?? (Bundle.main.path(forResource: "doraemon", ofType: "png").flatMap { UIImage(contentsOfFile: $0) }) {
                            Image(uiImage: uiImg)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color.cyan.opacity(0.9), Color.blue.opacity(0.6)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 3
                                        )
                                    )
                                .shadow(color: Color.cyan.opacity(0.5), radius: 14, y: 6)
                                .padding(.top, 20)
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.cyan)
                                .padding(.top, 20)
                        }
                        
                        VStack(spacing: 6) {
                            Text(isRegisterMode ? "Tạo Tài Khoản" : "Chào Mừng Trở Lại")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(theme.primaryText)
                            
                            Text(isRegisterMode ? "Đăng ký tài khoản để kích hoạt bản quyền Build File" : "Chọn chế độ, tạo cấu hình và quản lý bản dựng của bạn")
                                .font(.caption)
                                .foregroundColor(theme.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        
                        // Server connectivity button (NO IP / URL shown)
                        Button(action: {
                            api.checkHealth { _ in }
                        }) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(api.isOnline ? Color.green : Color.orange)
                                    .frame(width: 8, height: 8)
                                Text(api.isOnline ? "Hệ Thống : Sẵn Sàng" : "Hệ Thống : Ngoại Tuyến")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(api.isOnline ? .green : .orange)
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 9))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(theme.cardBackground)
                            .clipShape(Capsule())
                        }
                    }
                    
                    // MARK: - Tab Switcher (Segmented Control)
                    Picker("", selection: $isRegisterMode) {
                        Text(loc.t("login")).tag(false)
                        Text(loc.t("register")).tag(true)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .disabled(isLoading)
                    .onChange(of: isRegisterMode) { _ in
                        errorMessage = nil
                        successMessage = nil
                        confirmPassword = ""
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Error / Success Banner
                    if let error = errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding()
                        .background(Color.red.opacity(0.12))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    if let success = successMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(success)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // MARK: - Input Form
                    VStack(spacing: 16) {
                        StudioFloatingField(title: loc.t("username"), icon: "person", text: $username)
                        StudioFloatingField(title: loc.t("password"), icon: "lock", text: $password, secure: true)
                        if isRegisterMode {
                            StudioFloatingField(title: "Xác nhận mật khẩu", icon: "lock.shield", text: $confirmPassword, secure: true)
                        }

                        // Action Button
                        Button(action: {
                            performAction()
                        }) {
                            HStack(spacing: 10) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: isRegisterMode ? "person.badge.plus" : "arrow.right.circle.fill")
                                        .font(.headline)
                                    Text(isRegisterMode ? "ĐĂNG KÝ TÀI KHOẢN" : "ĐĂNG NHẬP NGAY")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [theme.accentColor, theme.accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(theme.currentTheme == .monochrome ? .black : .white)
                            .cornerRadius(14)
                            .shadow(color: Color.cyan.opacity(0.3), radius: 10, y: 4)
                        }
                        .disabled(isLoading || username.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty)
                        .opacity((username.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty) ? 0.6 : 1.0)
                    }
                    .disabled(isLoading)
                    .padding(20)
                    .background(theme.cardBackground)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(theme.cardBorder, lineWidth: 1))
                    .padding(.horizontal)
                    
                    // MARK: - Device HWID Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "cpu")
                                .foregroundColor(.cyan)
                            Text("MÃ ĐỊNH DANH THIẾT BỊ (HWID)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(theme.secondaryText)
                            Spacer()
                            Button(action: {
                                UIPasteboard.general.string = api.hwid
                                copiedHwid = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copiedHwid = false
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: copiedHwid ? "checkmark" : "doc.on.doc")
                                    Text(copiedHwid ? "Đã chép" : "Sao chép")
                                }
                                .font(.caption2)
                                .foregroundColor(.cyan)
                            }
                        }
                        
                        Text(api.hwid)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(theme.primaryText)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Text("HWID dùng để liên kết bảo vệ tài khoản và cấp phép tính năng mod.")
                            .font(.system(size: 10))
                            .foregroundColor(theme.secondaryText)
                    }
                    .padding(14)
                    .background(theme.cardBackground)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.cardBorder, lineWidth: 1))
                    .padding(.horizontal)
                    
                    // Footer
                    Text("Build File Studio © 2026 • AI Engine Gatekeeper")
                        .font(.caption2)
                        .foregroundColor(theme.secondaryText.opacity(0.6))
                        .padding(.bottom, 24)
                }
            }
        }
    }
    
    private func performAction() {
        guard !isLoading else { return }
        APIService.hideKeyboard()
        errorMessage = nil
        successMessage = nil
        
        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUser.isEmpty, !password.isEmpty else {
            errorMessage = "Vui lòng nhập đầy đủ tài khoản và mật khẩu."
            return
        }
        
        if isRegisterMode {
            guard password == confirmPassword else {
                errorMessage = "Mật khẩu xác nhận không khớp."
                return
            }
            guard password.count >= 4 else {
                errorMessage = "Mật khẩu phải có ít nhất 4 ký tự."
                return
            }
            
            isLoading = true
            api.register(username: trimmedUser, password: password) { result in
                isLoading = false
                switch result {
                case .success:
                    successMessage = "Đăng ký thành công! Đã tự động kích hoạt tài khoản."
                case .failure(let err):
                    errorMessage = err.localizedDescription
                }
            }
        } else {
            isLoading = true
            api.login(username: trimmedUser, password: password) { result in
                isLoading = false
                switch result {
                case .success:
                    // Authenticated! ContentView will automatically transition to main app
                    break
                case .failure(let err):
                    errorMessage = err.localizedDescription
                }
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
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(focused ? Color.accentColor : Color.primary.opacity(0.12), lineWidth: focused ? 1.5 : 1))
        .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: raised)
    }
}
