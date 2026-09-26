import SwiftUI

public struct AdminDashboardView: View {
    @ObservedObject private var api = AdminAPIService.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var tab = 0
    @State private var confirmLogout = false
    @State private var changingMode = false
    @State private var modeError = ""
    public init() {}

    public var body: some View {
        TabView(selection: $tab) {
            NavigationView { overview }.navigationViewStyle(.stack)
                .tabItem { Label("Tổng quan", systemImage: "square.grid.2x2") }.tag(0)
            NavigationView { AdminUsersView().navigationTitle("Tài khoản").navigationBarTitleDisplayMode(.inline) }.navigationViewStyle(.stack)
                .tabItem { Label("Tài khoản", systemImage: "person.2") }.tag(1)
            NavigationView { AdminBlacklistView().navigationTitle("Thiết bị").navigationBarTitleDisplayMode(.inline) }.navigationViewStyle(.stack)
                .tabItem { Label("Thiết bị", systemImage: "shield") }.tag(2)
            NavigationView { AdminLogsView().navigationTitle("Hoạt động").navigationBarTitleDisplayMode(.inline) }.navigationViewStyle(.stack)
                .tabItem { Label("Nhật ký", systemImage: "clock") }.tag(3)
        }
        .accentColor(theme.accentColor)
        .onAppear { api.fetchData(); setupBars() }
        .onChange(of: theme.currentTheme) { _ in setupBars() }
        .confirmationDialog("Đăng xuất trang quản trị?", isPresented: $confirmLogout, titleVisibility: .visible) {
            Button("Đăng xuất", role: .destructive) { api.logout() }
            Button("Hủy", role: .cancel) {}
        }
    }
    private var overview: some View {
        ScrollView {
            VStack(spacing: 22) {
                StudioHero(eyebrow: "MEONXT / ADMIN", title: "Chào mừng, Admin.", subtitle: "Theo dõi tài khoản, quản lý quyền truy cập và hoạt động của Studio.", icon: "square.grid.2x2")
                HStack(spacing: 8) {
                    Circle().fill(api.isOnline ? Color.green : .orange).frame(width: 8, height: 8)
                    Text(api.isOnline ? "Đã kết nối" : "Chưa kết nối").font(.caption.weight(.semibold))
                    Spacer()
                    if let updated = api.lastRefreshed { Text(updated, style: .time).font(.caption.monospacedDigit()) }
                }.foregroundColor(theme.secondaryText).padding(.horizontal, 4)
                if let error = api.refreshError {
                    StudioPanel("Chưa thể đồng bộ", icon: "exclamationmark.arrow.triangle.2.circlepath") {
                        Text(error).font(.subheadline)
                        Button("Thử lại") { api.fetchData() }.buttonStyle(StudioActionStyle())
                    }
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    metric("Tài khoản", count: api.users.count, icon: "person.2", destination: 1)
                    metric("Tài khoản VIP", count: api.users.filter { $0.role >= 1 }.count, icon: "crown", destination: 1)
                    metric("Thiết bị chặn", count: api.blacklist.count, icon: "shield.slash", destination: 2)
                    metric("Nhật ký", count: api.logs.count, icon: "clock.arrow.circlepath", destination: 3)
                }
                StudioPanel("Chế độ Free Cache", icon: "switch.2") {
                    Text(api.isFreeCacheEnabled ? "Tài khoản Free có thể tạo Cache." : "Chỉ tài khoản VIP có thể tạo Cache.").font(.subheadline).foregroundColor(theme.secondaryText)
                    if !modeError.isEmpty { Text(modeError).font(.caption).foregroundColor(.red) }
                    Button {
                        changingMode = true; modeError = ""
                        api.toggleFreeCache(enabled: !api.isFreeCacheEnabled) { success in
                            changingMode = false
                            if !success { modeError = "Không thể cập nhật chế độ. Vui lòng thử lại." }
                        }
                    } label: {
                        HStack {
                            if changingMode { ProgressView() }
                            Text(changingMode ? "Đang cập nhật…" : (api.isFreeCacheEnabled ? "Tắt Free Cache" : "Bật Free Cache"))
                        }
                    }.buttonStyle(StudioActionStyle(secondary: true)).disabled(changingMode || api.lastRefreshed == nil)
                }
                StudioPanel("Giao diện quản trị", icon: "paintpalette") {
                    Picker("Giao diện", selection: $theme.currentTheme) {
                        ForEach(AppThemeMode.allCases) { Text($0.title).tag($0) }
                    }.pickerStyle(.segmented)
                }
                Button(role: .destructive) { confirmLogout = true } label: {
                    Label("Đăng xuất", systemImage: "rectangle.portrait.and.arrow.right").frame(minHeight: 48)
                }
            }.padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }
        .background(theme.backgroundColor.ignoresSafeArea()).foregroundColor(theme.primaryText)
        .navigationTitle("Studio Admin").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { api.fetchData() } label: { Image(systemName: "arrow.clockwise") }.disabled(api.isRefreshing).accessibilityLabel("Làm mới dữ liệu")
            }
        }
        .safeAreaInset(edge: .bottom) { if api.isRefreshing { StudioBusyBar(text: "Đang đồng bộ dữ liệu…") } }
    }
    private func metric(_ title: String, count: Int, icon: String, destination: Int) -> some View {
        Button { tab = destination } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack { Image(systemName: icon).foregroundColor(theme.accentColor); Spacer(); Image(systemName: "arrow.up.right").foregroundColor(theme.secondaryText) }
                Text(api.lastRefreshed == nil ? "—" : "\(count)").font(.system(.largeTitle, design: .rounded).bold())
                Text(title).font(.subheadline).foregroundColor(theme.secondaryText)
            }.padding(20).frame(maxWidth: .infinity, alignment: .leading).foregroundColor(theme.primaryText)
                .background(theme.cardBackground).cornerRadius(24)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(theme.cardBorder, lineWidth: 1))
        }.buttonStyle(.plain)
    }
    private func setupBars() {
        let navigation = UINavigationBarAppearance()
        navigation.configureWithOpaqueBackground()
        navigation.backgroundColor = UIColor(theme.backgroundColor)
        navigation.titleTextAttributes = [.foregroundColor: UIColor(theme.primaryText)]
        UINavigationBar.appearance().standardAppearance = navigation
        UINavigationBar.appearance().scrollEdgeAppearance = navigation
        let tabs = UITabBarAppearance()
        tabs.configureWithOpaqueBackground()
        tabs.backgroundColor = UIColor(theme.backgroundColor)
        UITabBar.appearance().standardAppearance = tabs
        UITabBar.appearance().scrollEdgeAppearance = tabs
    }
}
