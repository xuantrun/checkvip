import SwiftUI

public struct ContentView: View {
    @State private var selectedTab: Int = 1
    @State private var enteredStudio = false
    @State private var isSidebarOpen: Bool = false
    
    @ObservedObject var api = APIService.shared
    @ObservedObject var loc = LocalizationManager.shared
    @ObservedObject var theme = ThemeManager.shared
    
    // Stealth mode
    @AppStorage("stealth_mode_enabled") private var isStealthMode: Bool = false
    
    public init() {}
    
    public var body: some View {
        Group {
            if api.isHwidBlocked {
                hwidLockView
            } else if api.isStarting || api.startupError != nil {
                startupView
            } else if !api.isAuthenticated {
                LoginView()
            } else if isStealthMode {
                stealthDisguiseView
            } else if !enteredStudio {
                welcomeView
            } else {
                mainContainerView
            }
        }
        .accentColor(theme.accentColor)
        .onChange(of: api.isAuthenticated) { _ in enteredStudio = false }
        .preferredColorScheme(theme.colorScheme)
        .onAppear {
            setupSystemBarAppearances()
        }
        .onChange(of: theme.currentTheme) { _ in
            setupSystemBarAppearances()
        }
    }
    
    private var startupView: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 52)).foregroundColor(theme.accentColor)
                Text("BUILD FILE STUDIO").font(.title2.bold())
                if api.isStarting {
                    ProgressView().tint(theme.accentColor)
                    Text(loc.isVN ? "Đang kiểm tra kết nối và phiên đăng nhập…" : "Checking connection and session…")
                        .foregroundColor(theme.secondaryText)
                } else {
                    Text(api.startupError ?? "").foregroundColor(theme.secondaryText)
                    Button(action: api.prepareSession) {
                        Label(loc.isVN ? "Thử lại" : "Try again", systemImage: "arrow.clockwise")
                            .padding().frame(maxWidth: .infinity)
                    }.buttonStyle(.borderedProminent)
                }
            }
            .multilineTextAlignment(.center).padding(32).frame(maxWidth: 480)
            .foregroundColor(theme.primaryText)
        }
    }

    private var welcomeView: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: "sparkles").font(.system(size: 44)).foregroundColor(theme.accentColor)
                    Text(loc.isVN ? "Chào mừng đến Studio" : "Welcome to Studio")
                        .font(.largeTitle.bold())
                    Text(api.currentUser).font(.title3).foregroundColor(theme.secondaryText)
                    Text(loc.isVN ? "Chọn không gian làm việc của bạn" : "Choose your workspace")
                        .font(.headline)
                    workspaceButton("Cache", subtitle: loc.isVN ? "Cấu hình và tạo bản dựng" : "Configure and build", icon: "square.stack.3d.up", tab: 1)
                    if api.isVIP {
                        workspaceButton("Shader", subtitle: loc.isVN ? "Màu sắc và hiệu ứng" : "Colors and effects", icon: "wand.and.stars", tab: 0)
                    }
                    if api.isVIP2 {
                        workspaceButton("Avatar", subtitle: loc.isVN ? "Tùy chỉnh nhân vật" : "Customize your character", icon: "person.crop.square", tab: 2)
                    }
                    workspaceButton(loc.isVN ? "Cài đặt" : "Settings", subtitle: loc.isVN ? "Giao diện và tài khoản" : "Appearance and account", icon: "slider.horizontal.3", tab: 4)
                }
                .padding(24).frame(maxWidth: 600).frame(maxWidth: .infinity)
            }
            .foregroundColor(theme.primaryText)
        }
    }

    private func workspaceButton(_ title: String, subtitle: String, icon: String, tab: Int) -> some View {
        Button {
            selectedTab = tab
            enteredStudio = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon).font(.title2).foregroundColor(theme.accentColor).frame(width: 36)
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.headline).foregroundColor(theme.primaryText)
                    Text(subtitle).font(.subheadline).foregroundColor(theme.secondaryText)
                }
                Spacer()
                Image(systemName: "arrow.up.right").foregroundColor(theme.secondaryText)
            }
            .padding(20).background(theme.cardBackground).cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(theme.cardBorder, lineWidth: 1))
        }.buttonStyle(.plain)
    }

    private func setupSystemBarAppearances() {
        let navBar = UINavigationBarAppearance()
        navBar.configureWithOpaqueBackground()
        navBar.backgroundColor = UIColor(theme.backgroundColor)
        navBar.titleTextAttributes = [
            .foregroundColor: UIColor(theme.primaryText),
            .font: UIFont.systemFont(ofSize: 17, weight: .bold)
        ]
        navBar.shadowColor = UIColor(theme.cardBorder)
        UINavigationBar.appearance().standardAppearance = navBar
        UINavigationBar.appearance().compactAppearance = navBar
        if #available(iOS 15.0, *) {
            UINavigationBar.appearance().scrollEdgeAppearance = navBar
        }
        
        let tabBar = UITabBarAppearance()
        tabBar.configureWithOpaqueBackground()
        tabBar.backgroundColor = UIColor(theme.backgroundColor)
        tabBar.shadowColor = UIColor(theme.cardBorder)
        
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]
        itemAppearance.normal.iconColor = UIColor.systemGray
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(theme.accentColor),
            .font: UIFont.systemFont(ofSize: 11, weight: .bold)
        ]
        itemAppearance.selected.iconColor = UIColor(theme.accentColor)
        
        tabBar.stackedLayoutAppearance = itemAppearance
        tabBar.inlineLayoutAppearance = itemAppearance
        tabBar.compactInlineLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = tabBar
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabBar
        }
    }
    
    // MARK: - Main Container with Top Bar & Direct Tab Bar
    private var mainContainerView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button { enteredStudio = false } label: {
                    Image(systemName: "square.grid.2x2").font(.title3)
                        .frame(width: 44, height: 44).background(theme.cardBackground).cornerRadius(14)
                }.accessibilityLabel(loc.isVN ? "Về trang chào mừng" : "Home")
                VStack(alignment: .leading, spacing: 3) {
                    Text("BUILD FILE").font(.subheadline.bold()).tracking(1)
                    Text(api.currentUser).font(.caption).foregroundColor(theme.secondaryText)
                }
                Spacer()
                Text(api.isVIP2 ? "VIP 2" : (api.isVIP ? "VIP 1" : "FREE"))
                    .font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 6)
                    .background(theme.accentColor.opacity(0.1)).foregroundColor(theme.accentColor).clipShape(Capsule())
                Circle().fill(api.isOnline ? Color.green : .orange).frame(width: 8, height: 8)
                    .accessibilityLabel(api.isOnline ? "Online" : "Offline")
            }.padding(.horizontal, 20).padding(.vertical, 8)
            TabView(selection: $selectedTab) {
                NavigationView {
                    if api.isVIP { GunModView() } else { vipShaderLockedView }
                }.navigationViewStyle(.stack).tabItem { Label("Shader", systemImage: "paintpalette") }.tag(0)
                NavigationView { HitboxModView() }.navigationViewStyle(.stack)
                    .tabItem { Label("Cache", systemImage: "square.stack.3d.up") }.tag(1)
                NavigationView {
                    if api.isVIP2 { AvatarModView() } else { vip2AvatarLockedView }
                }.navigationViewStyle(.stack).tabItem { Label("Avatar", systemImage: "person.crop.square") }.tag(2)
                NavigationView { AuthorCreditsView() }.navigationViewStyle(.stack)
                    .tabItem { Label(loc.isVN ? "Kết nối" : "Connect", systemImage: "bubble.left.and.bubble.right") }.tag(3)
                NavigationView { SettingsView() }.navigationViewStyle(.stack)
                    .tabItem { Label(loc.isVN ? "Cài đặt" : "Settings", systemImage: "slider.horizontal.3") }.tag(4)
            }.accentColor(theme.accentColor)
        }.foregroundColor(theme.primaryText).background(theme.backgroundColor.ignoresSafeArea())
    }

    // MARK: - Stealth Disguise View (Chạm 3 lần để mở lại, không hiển thị text gợi ý)
    private var stealthDisguiseView: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            StudioEmptyState(title: "Không gian riêng tư", message: "Chạm ba lần để quay lại Studio.", icon: "eye.slash")
        }.contentShape(Rectangle()).onTapGesture(count: 3) { isStealthMode = false }
    }

    // MARK: - HWID Blocked Lock View
    private var hwidLockView: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            VStack(spacing: 20) {
                StudioEmptyState(title: "Thiết bị bị tạm khóa", message: "Liên hệ quản trị viên để được hỗ trợ kiểm tra quyền truy cập.", icon: "lock.shield")
                Text(api.hwid).font(.caption.monospaced()).textSelection(.enabled).foregroundColor(theme.secondaryText)
                Link("Liên hệ hỗ trợ", destination: URL(string: "https://t.me/truongdeptrai7")!)
                    .buttonStyle(StudioActionStyle())
            }.padding(24).frame(maxWidth: 540)
        }
    }

    private var vipShaderLockedView: some View {
        lockedWorkspace(title: "Shader Studio", tier: "VIP 1", icon: "paintpalette")
    }
    private var vip2AvatarLockedView: some View {
        lockedWorkspace(title: "Avatar Studio", tier: "VIP 2", icon: "person.crop.square")
    }
    private func lockedWorkspace(title: String, tier: String, icon: String) -> some View {
        ScrollView {
            VStack(spacing: 22) {
                StudioHero(eyebrow: "STUDIO / \(tier)", title: title, subtitle: "Không gian này cần quyền \(tier).", icon: icon)
                StudioPanel("Mở rộng không gian làm việc", icon: "lock") {
                    Text("Liên hệ quản trị viên để nâng cấp quyền. Các tính năng hiện có của bạn vẫn sẵn sàng trong Studio.")
                        .font(.subheadline).foregroundColor(theme.secondaryText)
                    Link("Liên hệ quản trị viên", destination: URL(string: "https://t.me/truongdeptrai7")!)
                        .buttonStyle(StudioActionStyle())
                    Button("Quay lại Cache") { selectedTab = 1 }.buttonStyle(StudioActionStyle(secondary: true))
                }
            }.padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(theme.backgroundColor.ignoresSafeArea()).navigationTitle(title).navigationBarTitleDisplayMode(.inline)
    }
}
