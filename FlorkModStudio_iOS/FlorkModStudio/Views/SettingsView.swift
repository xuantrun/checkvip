import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var api = APIService.shared
    @ObservedObject private var loc = LocalizationManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    
    @State private var isChecking: Bool = false
    @State private var checkStatus: String = ""
    @State private var showLoginSheet: Bool = false
    @State private var copiedHwid: Bool = false
    @State private var copiedKey: Bool = false
    @AppStorage("stealth_mode_enabled") private var isStealthMode: Bool = false
    
    public init() {}
    
    public var body: some View {
        Form {
            // MARK: - ACCOUNT SECTION
            Section(header: Text(loc.t("tab_account"))) {
                if api.isAuthenticated {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title2)
                                .foregroundColor(.cyan)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(api.currentUser)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                Text("Đã kích hoạt bản quyền")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                            Spacer()
                            Button(action: {
                                api.logout()
                            }) {
                                Text(loc.t("logout"))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.red.opacity(0.12))
                                    .cornerRadius(8)
                            }
                        }
                        
                        Divider().padding(.vertical, 4)
                        
                        // API Key row
                        HStack {
                            Text(loc.t("api_key_label") + ":")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(api.apiKey)
                                .font(.system(size: 10, design: .monospaced))
                                .lineLimit(1)
                            Spacer()
                            Button(action: {
                                UIPasteboard.general.string = api.apiKey
                                copiedKey = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedKey = false }
                            }) {
                                Text(copiedKey ? "Đã chép" : "Chép")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.cyan)
                            }
                        }
                        
                        // HWID row
                        HStack {
                            Text(loc.t("hwid_label") + ":")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(api.hwid)
                                .font(.system(size: 9, design: .monospaced))
                                .lineLimit(1)
                            Spacer()
                            Button(action: {
                                UIPasteboard.general.string = api.hwid
                                copiedHwid = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedHwid = false }
                            }) {
                                Text(copiedHwid ? "Đã chép" : "Chép")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.cyan)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    Button(action: {
                        showLoginSheet = true
                    }) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.cyan)
                            Text("Đăng Nhập / Đăng Ký Tài Khoản")
                                .fontWeight(.bold)
                                .foregroundColor(.cyan)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            // MARK: - THEME & APPEARANCE
            Section(header: Text(loc.t("theme_dark") + " / " + loc.t("theme_light"))) {
                Picker("Giao Diện", selection: $theme.currentTheme) {
                    ForEach(AppThemeMode.allCases) { m in
                        Text(m.title).tag(m)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.vertical, 4)
            }
            
            // MARK: - LANGUAGE
            Section(header: Text(loc.t("language"))) {
                Picker("Ngôn Ngữ", selection: $loc.currentLanguage) {
                    ForEach(AppLanguage.allCases) { l in
                        Text(l.displayName).tag(l)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.vertical, 4)
            }
            
            // MARK: - SYSTEM SECURITY & SERVER STATUS (100% HIDDEN URL/IP)
            Section(header: Text("BẢO MẬT & HỆ THỐNG MÁY CHỦ")) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Circle()
                            .fill(api.isOnline ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(api.isOnline ? "Hệ Thống Trực Tuyến" : "Hệ Thống Ngoại Tuyến")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(api.isOnline ? .green : .red)
                        Spacer()
                        Text("Mã Hóa 256-bit")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.cyan.opacity(0.12))
                            .foregroundColor(.cyan)
                            .cornerRadius(6)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.cyan)
                            .font(.caption)
                        Text("Đường truyền đám mây được mã hóa đa tầng, chống rò rỉ.")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    Divider().padding(.vertical, 2)
                    
                    HStack {
                        Button(action: {
                            isChecking = true
                            checkStatus = "Đang kiểm tra..."
                            api.checkHealth { success in
                                isChecking = false
                                checkStatus = success ? "Hoạt động tốt!" : "Mất kết nối!"
                            }
                        }) {
                            HStack(spacing: 6) {
                                if isChecking {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                                Text("Kiểm Tra Kết Nối")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.cyan)
                        }
                        .disabled(isChecking)
                        
                        Spacer()
                        
                        if !checkStatus.isEmpty {
                            Text(checkStatus)
                                .font(.caption2)
                                .foregroundColor(api.isOnline ? .green : .red)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // MARK: - STEALTH & PRIVACY
            Section(header: Text("BẢO MẬT & ẨN GIAO DIỆN")) {
                Toggle(isOn: $isStealthMode) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Chế Độ Ẩn Danh (Stealth Mode)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Ngụy trang giao diện ứng dụng thành trình giám sát hệ thống bảo mật")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // MARK: - GAME GUIDE
            Section(header: Text("TÀI LIỆU & HƯỚNG DẪN")) {
                NavigationLink(destination: GameGuideView()) {
                    HStack(spacing: 12) {
                        Image(systemName: "book.fill")
                            .foregroundColor(.cyan)
                        Text("Hướng Dẫn Cài Đặt & Sử Dụng Chi Tiết")
                            .font(.subheadline)
                    }
                }
            }
            
            // MARK: - SYSTEM INFO
            Section(header: Text("THÔNG TIN PHIÊN BẢN")) {
                HStack {
                    Text("Ứng Dụng:")
                    Spacer()
                    Text("Build File")
                        .foregroundColor(.cyan)
                        .fontWeight(.bold)
                }
                HStack {
                    Text("Phiên Bản:")
                    Spacer()
                    Text("v2.0.3 (Official)")
                        .foregroundColor(.gray)
                }
                HStack {
                    Text("Tương Thích:")
                    Spacer()
                    Text("iOS 15.0 - 27+")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Cài Đặt")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLoginSheet) {
            LoginView()
        }
    }
}
