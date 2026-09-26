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
            .foregroundColor: UIColor(Color.cyan),
            .font: UIFont.systemFont(ofSize: 11, weight: .bold)
        ]
        itemAppearance.selected.iconColor = UIColor(Color.cyan)
        
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
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
            // TOP BAR: Brand Logo, Name & Language Switcher
            HStack(spacing: 12) {
                // Logo with Halo Glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.cyan.opacity(0.35), Color.clear],
                                center: .center,
                                startRadius: 4,
                                endRadius: 20
                            )
                        )
                        .frame(width: 38, height: 38)
                    
                    if let uiImg = UIImage(named: "doraemon") ?? (Bundle.main.path(forResource: "doraemon", ofType: "png").flatMap { UIImage(contentsOfFile: $0) }) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.cyan.opacity(0.8), lineWidth: 1.5))
                    } else {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text("BUILD FILE")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(theme.primaryText)
                        
                        Text(api.isVIP ? "PRE" : "FREE")
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(api.isVIP ? Color.yellow.opacity(0.2) : Color.cyan.opacity(0.2))
                            .foregroundColor(api.isVIP ? .yellow : .cyan)
                            .clipShape(Capsule())
                    }
                    
                    Text("STUDIO • BUILD ENGINE")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(theme.secondaryText)
                }
                
                Spacer()
                
                // Realtime Server Status Badge
                HStack(spacing: 5) {
                    ZStack {
                        Circle()
                            .fill(api.isOnline ? Color.green : Color.red)
                            .frame(width: 7, height: 7)
                        Circle()
                            .stroke(api.isOnline ? Color.green.opacity(0.5) : Color.red.opacity(0.5), lineWidth: 1.5)
                            .frame(width: 13, height: 13)
                    }
                    Text(api.isOnline ? "ONLINE" : "OFFLINE")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(api.isOnline ? .green : .red)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
                
                // VN / ENG toggle button
                Button(action: {
                    loc.currentLanguage = (loc.currentLanguage == .vietnamese ? .english : .vietnamese)
                }) {
                    HStack(spacing: 3) {
                        Text(loc.currentLanguage == .vietnamese ? "🇻🇳" : "🇬🇧")
                            .font(.system(size: 12))
                        Text(loc.currentLanguage == .vietnamese ? "VN" : "EN")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(theme.primaryText)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(theme.backgroundColor)
            
            Divider().background(theme.cardBorder)
            
            // TAB VIEW (With requested icons for each tab)
            TabView(selection: $selectedTab) {
                NavigationView {
                    if api.isVIP {
                        GunModView()
                    } else {
                        vipShaderLockedView
                    }
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label("Shader", systemImage: "wand.and.stars")
                }
                .tag(0)
                
                NavigationView {
                    HitboxModView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label("Cache_res", systemImage: "bolt.shield.fill")
                }
                .tag(1)
                
                NavigationView {
                    if api.isVIP2 {
                        AvatarModView()
                    } else {
                        vip2AvatarLockedView
                    }
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label(loc.t("tab_avatar"), systemImage: "figure.arms.open")
                }
                .tag(2)
                
                NavigationView {
                    AuthorCreditsView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label(loc.isVN ? "Sáng Tác" : "Credits", systemImage: "person.crop.circle.fill")
                }
                .tag(3)
                
                NavigationView {
                    SettingsView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .tabItem {
                    Label(loc.isVN ? "Cài Đặt" : "Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
            }
            .accentColor(theme.accentColor)
        }
        }
    }
    
    // MARK: - Stealth Disguise View (Chạm 3 lần để mở lại, không hiển thị text gợi ý)
    private var stealthDisguiseView: some View {
        ZStack {
            Color(red: 0.03, green: 0.04, blue: 0.06).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "cpu")
                    .font(.system(size: 60))
                    .foregroundColor(.gray.opacity(0.5))
                
                Text("Hệ Thống Thiết Bị iOS")
                    .font(.headline)
                    .foregroundColor(.gray)
                
                Text("RAM: 3.8 GB / 4.0 GB • CPU: 8% • Pin: 92%")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.7))
                
                ProgressView(value: 0.76)
                    .progressViewStyle(LinearProgressViewStyle(tint: .gray.opacity(0.35)))
                    .frame(width: 200)
                
                Text("Hệ thống bảo mật đang hoạt động")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.35))
                    .padding(.top, 30)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 3) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isStealthMode = false
            }
        }
    }
    
    // MARK: - HWID Blocked Lock View
    private var hwidLockView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "shield.slash.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.red)
                
                VStack(spacing: 8) {
                    Text("THIẾT BỊ BỊ TẠM KHÓA")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                    
                    Text("Mã HWID của thiết bị này đã bị quản trị viên khóa truy cập. Vui lòng liên hệ hỗ trợ.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                
                Text("HWID: \(api.hwid)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - VIP Shader Locked View
    private var vipShaderLockedView: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 30)
                
                // Glowing Gold Crown / Shield Icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.yellow.opacity(0.25), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    Circle()
                        .fill(Color(red: 0.12, green: 0.10, blue: 0.04))
                        .frame(width: 90, height: 90)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 2.5
                                )
                        )
                    
                    Image(systemName: "crown.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow)
                }
                
                VStack(spacing: 8) {
                    Text(loc.isVN ? "TÍNH NĂNG VIP ĐỘC QUYỀN" : "VIP EXCLUSIVE FEATURE")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundColor(theme.primaryText)
                    
                    HStack(spacing: 6) {
                        Text(loc.isVN ? "Tài khoản hiện tại:" : "Current Account:")
                            .font(.system(size: 12))
                            .foregroundColor(theme.secondaryText)
                        
                        Text(loc.isVN ? "FREE USER (CẤP 0)" : "FREE USER (TIER 0)")
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.gray)
                            .clipShape(Capsule())
                    }
                }
                
                // Explanatory Card
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 18))
                        
                        Text(loc.isVN ?
                             "Tab Shader (tùy biến màu súng, X-Ray, phát sáng) yêu cầu tài khoản được Quản trị viên cấp quyền VIP (Cấp 1)." :
                             "Shader tab (gun customizer, X-Ray, glow) requires an account granted VIP status (Tier 1) by Admin.")
                            .font(.subheadline)
                            .foregroundColor(theme.primaryText)
                    }
                    
                    Divider().background(theme.cardBorder)
                    
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 18))
                        
                        Text(loc.isVN ?
                             "Tài khoản Free của bạn được sử dụng toàn bộ tính năng Tab Cache (Hitbox, Kéo tâm đầu, Magic Bullet) mặc định 100% miễn phí!" :
                             "Your Free account has full access to the Cache Tab (Hitbox, Head Drag, Magic Bullet) 100% free by default!")
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryText)
                    }
                }
                .padding(16)
                .background(theme.cardBackground)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.cardBorder, lineWidth: 1))
                .padding(.horizontal)
                
                // Action Buttons
                VStack(spacing: 12) {
                    // Switch to Free Cache Tab Button
                    Button(action: {
                        selectedTab = 1
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.shield.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text(loc.isVN ? "Dùng Tab Cache (Miễn Phí Mặc Định)" : "Use Cache Tab (Free Default)")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(14)
                        .shadow(color: Color.cyan.opacity(0.35), radius: 8, y: 4)
                    }
                    
                    // Contact Admin for VIP Button
                    Button(action: {
                        if let url = URL(string: "https://t.me/truongdeptrai7") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            Text(loc.isVN ? "Liên Hệ Admin Cấp Quyền VIP (@truongdeptrai7)" : "Contact Admin for VIP (@truongdeptrai7)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.primaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(theme.cardBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)
                
                Text(loc.isVN ? "⚡ Khi Admin cấp VIP, tab này sẽ tự động mở khóa ngay lập tức." : "⚡ Once Admin grants VIP, this tab unlocks immediately.")
                    .font(.caption2)
                    .foregroundColor(theme.secondaryText.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer().frame(height: 20)
            }
        }
        .navigationTitle("Shader VIP")
    }
    }
    
    // MARK: - VIP 2 Avatar Locked View
    private var vip2AvatarLockedView: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 30)
                    
                    // Glowing Purple/Gold Crown + Avatar Icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.purple.opacity(0.35), Color.clear],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 75
                                )
                            )
                            .frame(width: 150, height: 150)
                        
                        Circle()
                            .fill(Color(red: 0.11, green: 0.06, blue: 0.16))
                            .frame(width: 96, height: 96)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(colors: [Color.purple, Color.yellow], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        lineWidth: 2.5
                                    )
                            )
                        
                        Image(systemName: "figure.arms.open")
                            .font(.system(size: 38))
                            .foregroundColor(.purple)
                            .overlay(
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.yellow)
                                    .offset(x: 14, y: -16)
                            )
                    }
                    
                    VStack(spacing: 8) {
                        Text(loc.isVN ? "YÊU CẦU VIP 2 (TIER 2)" : "VIP 2 EXCLUSIVE (TIER 2)")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(theme.primaryText)
                        
                        HStack(spacing: 6) {
                            Text(loc.isVN ? "Tài khoản hiện tại:" : "Current Account:")
                                .font(.system(size: 12))
                                .foregroundColor(theme.secondaryText)
                            
                            if api.userRole == 1 {
                                Text(loc.isVN ? "⭐ VIP 1 (SHADER ONLY)" : "⭐ VIP 1 (SHADER ONLY)")
                                    .font(.system(size: 10, weight: .black))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.yellow.opacity(0.2))
                                    .foregroundColor(.yellow)
                                    .clipShape(Capsule())
                            } else {
                                Text(loc.isVN ? "🛡️ FREE USER (CẤP 0)" : "🛡️ FREE USER (TIER 0)")
                                    .font(.system(size: 10, weight: .black))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.gray)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    // Explanatory Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "wand.and.stars")
                                .foregroundColor(.purple)
                                .font(.system(size: 18))
                            
                            Text(loc.isVN ?
                                 "Tính năng Make Avatar (AssetIndexer Mod Unity: Antena trên đầu, Súng siêu to Big Gun, Scale Nam/Nữ, Rig Bone) độc quyền cho VIP 2." :
                                 "Make Avatar (Unity AssetIndexer: Head Antena, Big Gun, Male/Female Scale, Rig Bone) is exclusive to VIP 2.")
                                .font(.subheadline)
                                .foregroundColor(theme.primaryText)
                        }
                        
                        Divider().background(theme.cardBorder)
                        
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.cyan)
                                .font(.system(size: 18))
                            
                            Text(loc.isVN ?
                                 (api.userRole == 1 ? 
                                  "Bạn đang sở hữu VIP 1 (dùng Shader). Hãy liên hệ Quản trị viên để nâng cấp lên VIP 2 để mở khóa Make Avatar!" :
                                  "Tài khoản Free được dùng Cache_res. Cần nâng lên VIP 2 để kích hoạt Make Avatar!") :
                                 (api.userRole == 1 ?
                                  "You currently have VIP 1 (Shader). Contact Admin to upgrade to VIP 2 for Make Avatar!" :
                                  "Free accounts can use Cache_res. Upgrade to VIP 2 for Make Avatar!"))
                                .font(.subheadline)
                                .foregroundColor(theme.secondaryText)
                        }
                    }
                    .padding(16)
                    .background(theme.cardBackground)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.purple.opacity(0.3), lineWidth: 1))
                    .padding(.horizontal)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Switch to Cache or Shader Button
                        Button(action: {
                            selectedTab = (api.isVIP ? 0 : 1)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: api.isVIP ? "wand.and.stars" : "bolt.shield.fill")
                                    .font(.system(size: 16, weight: .bold))
                                Text(api.isVIP ? (loc.isVN ? "Dùng Tab Shader (VIP 1)" : "Use Shader Tab (VIP 1)") : (loc.isVN ? "Dùng Tab Cache (Miễn Phí)" : "Use Cache Tab (Free)"))
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(colors: [Color.purple, Color.blue], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(14)
                            .shadow(color: Color.purple.opacity(0.35), radius: 8, y: 4)
                        }
                        
                        // Contact Admin for VIP 2 Button
                        Button(action: {
                            if let url = URL(string: "https://t.me/truongdeptrai7") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.yellow)
                                Text(loc.isVN ? "Nâng Cấp VIP 2 - Admin (@truongdeptrai7)" : "Upgrade to VIP 2 - Admin (@truongdeptrai7)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.primaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(theme.cardBackground)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.purple.opacity(0.5), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Text(loc.isVN ? "⚡ Khi Admin cấp quyền VIP 2, tab này sẽ tự động mở khóa ngay lập tức." : "⚡ Once Admin grants VIP 2, this tab unlocks immediately.")
                        .font(.caption2)
                        .foregroundColor(theme.secondaryText.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer().frame(height: 20)
                }
            }
            .navigationTitle("Make Avt VIP 2")
        }
    }
}
