import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var api = APIService.shared
    @ObservedObject private var loc = LocalizationManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var checking = false
    @State private var status = ""
    @State private var copied = ""
    @State private var confirmLogout = false
    @AppStorage("stealth_mode_enabled") private var stealth = false
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                StudioHero(eyebrow: "STUDIO / SETTINGS", title: "Theo cách của bạn.", subtitle: "Giao diện, tài khoản và tùy chọn cho mỗi lần sử dụng.", icon: "slider.horizontal.3")
                StudioPanel("Tài khoản", icon: "person.crop.circle") {
                    HStack(spacing: 14) {
                        Image(systemName: "person.fill").font(.title2).foregroundColor(theme.accentColor)
                            .frame(width: 52, height: 52).background(theme.accentColor.opacity(0.1)).clipShape(Circle())
                        VStack(alignment: .leading, spacing: 5) {
                            Text(api.currentUser).font(.title3.bold())
                            Text(api.isVIP2 ? "VIP 2 · Toàn bộ Studio" : (api.isVIP ? "VIP 1 · Shader & Cache" : "Free · Cache"))
                                .font(.subheadline).foregroundColor(theme.secondaryText)
                        }
                        Spacer()
                    }
                    Divider()
                    copyRow("Mã thiết bị", value: api.hwid, icon: "cpu")
                    copyRow("API Key", value: api.apiKey, icon: "key", masked: true)
                }
                StudioPanel("Giao diện", icon: "paintpalette") {
                    ForEach(AppThemeMode.allCases) { mode in
                        Button { theme.currentTheme = mode } label: {
                            HStack(spacing: 14) {
                                Image(systemName: mode == .light ? "sun.max" : (mode == .dark ? "moon" : "circle.lefthalf.filled"))
                                    .frame(width: 28).foregroundColor(theme.accentColor)
                                Text(mode.title).foregroundColor(theme.primaryText)
                                Spacer()
                                Image(systemName: theme.currentTheme == mode ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(theme.currentTheme == mode ? theme.accentColor : theme.secondaryText)
                            }.padding(14).background(theme.primaryText.opacity(0.035)).cornerRadius(16)
                        }.buttonStyle(.plain)
                    }
                }
                StudioPanel("Ngôn ngữ", icon: "globe") {
                    Picker("Ngôn ngữ", selection: $loc.currentLanguage) {
                        ForEach(AppLanguage.allCases) { language in Text(language.displayName).tag(language) }
                    }.pickerStyle(.segmented)
                }
                StudioPanel("Kết nối", icon: "network") {
                    Label(api.isOnline ? "Máy chủ đang trực tuyến" : "Chưa kết nối máy chủ", systemImage: api.isOnline ? "checkmark.circle.fill" : "wifi.slash")
                        .foregroundColor(api.isOnline ? .green : .orange)
                    if !status.isEmpty { Text(status).font(.caption).foregroundColor(theme.secondaryText) }
                    Button {
                        checking = true
                        api.checkHealth { online in
                            checking = false
                            status = online ? "Kết nối thành công." : "Không thể kết nối. Hãy kiểm tra mạng và thử lại."
                        }
                    } label: {
                        HStack { if checking { ProgressView() }; Text(checking ? "Đang kiểm tra…" : "Kiểm tra kết nối") }
                    }.buttonStyle(StudioActionStyle(secondary: true)).disabled(checking)
                }
                StudioPanel("Riêng tư", icon: "eye.slash") {
                    Toggle("Ẩn không gian làm việc", isOn: $stealth)
                    Text("Chạm ba lần vào màn hình riêng tư để quay lại Studio.").font(.subheadline).foregroundColor(theme.secondaryText)
                }
                StudioPanel("Trợ giúp & phiên bản", icon: "info.circle") {
                    NavigationLink(destination: GameGuideView()) {
                        HStack { Label("Hướng dẫn sử dụng", systemImage: "book"); Spacer(); Image(systemName: "chevron.right") }.frame(minHeight: 44)
                    }
                    Divider()
                    HStack {
                        Text("Build File Studio")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—").foregroundColor(theme.secondaryText)
                    }.font(.subheadline)
                }
                Button(role: .destructive) { confirmLogout = true } label: {
                    Label("Đăng xuất tài khoản", systemImage: "rectangle.portrait.and.arrow.right").frame(minHeight: 48)
                }
            }.padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }
        .foregroundColor(theme.primaryText).background(theme.backgroundColor.ignoresSafeArea())
        .navigationTitle("Cài đặt").navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Đăng xuất khỏi Studio?", isPresented: $confirmLogout, titleVisibility: .visible) {
            Button("Đăng xuất", role: .destructive) { api.logout() }
            Button("Hủy", role: .cancel) {}
        }
    }
    private func copyRow(_ title: String, value: String, icon: String, masked: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(theme.secondaryText).frame(width: 24)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(masked ? "••••••••" : value).font(.caption.monospaced()).lineLimit(1).truncationMode(.middle).foregroundColor(theme.secondaryText)
            }
            Spacer()
            Button { UIPasteboard.general.string = value; copied = title } label: {
                Image(systemName: copied == title ? "checkmark" : "doc.on.doc").frame(width: 44, height: 44)
            }.accessibilityLabel("Sao chép \(title)")
        }
    }
}
