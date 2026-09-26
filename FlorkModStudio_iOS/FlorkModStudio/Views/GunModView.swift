import SwiftUI

public struct GunModView: View {
    @State private var selectedVersion: GameVersion = .fft
    @State private var gunColor: Color = Color(red: 1.0, green: 1.0, blue: 0.0) // Vàng Chanh
    @State private var backdropColor: Color = Color(red: 1.0, green: 1.0, blue: 1.0) // Trắng Tuyết
    @State private var outlineWidth: Float = 2.0
    
    // Status & Feedback
    @State private var isProcessing: Bool = false
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var showLoginSheet: Bool = false
    
    @ObservedObject private var apiService = APIService.shared
    @ObservedObject private var loc = LocalizationManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                
                StudioHero(eyebrow: "STUDIO / SHADER", title: "Màu sắc của bạn.", subtitle: "Chọn phiên bản, phối màu và xem trước bản dựng.", icon: "paintpalette")
                // MARK: - Bước 1: Chọn Phiên Bản Game
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "gamecontroller.fill")
                            .foregroundColor(theme.accentColor)
                        Text(loc.t("gun_step1"))
                            .font(.headline)
                            .foregroundColor(theme.primaryText)
                        Spacer()
                    }
                    
                    VStack(spacing: 10) {
                        ForEach(GameVersion.allCases) { ver in
                            Button(action: {
                                selectedVersion = ver
                            }) {
                                HStack(spacing: 14) {
                                    // Authentic Game Artwork Cover
                                    gameCoverImage(for: ver)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 52, height: 52)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.18), lineWidth: 1))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(ver == .fft ? "Free Fire Thường" : "Free Fire MAX")
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(theme.primaryText)
                                            Spacer()
                                            if selectedVersion == ver {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(theme.accentColor)
                                                    .font(.system(size: 18))
                                            } else {
                                                Circle()
                                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
                                                    .frame(width: 18, height: 18)
                                            }
                                        }
                                        Text(ver == .fft ? "Gói chuẩn com.dts.freefireth • Tối ưu FPS" : "Gói đồ họa cao com.dts.freefiremax • Ultra HD")
                                            .font(.caption)
                                            .foregroundColor(theme.secondaryText)
                                            .lineLimit(1)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background(selectedVersion == ver ? theme.accentColor.opacity(0.12) : theme.primaryText.opacity(0.04))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(selectedVersion == ver ? theme.accentColor : theme.primaryText.opacity(0.1), lineWidth: 1.5)
                                )
                            }
                        }
                    }
                }
                .padding()
                .background(theme.cardBackground)
                .cornerRadius(24)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(theme.cardBorder, lineWidth: 1))
                
                // MARK: - Xem Trước Trực Quan Súng M4A1
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Circle()
                            .fill(gunColor)
                            .frame(width: 10, height: 10)
                        Text("Xem Trước Trực Quan Súng")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primaryText)
                        Spacer()
                        Text("DÂY VÀNG 2 MÀU")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.yellow, lineWidth: 1))
                    }
                    
                    GunPreviewCanvas(gunColor: gunColor, backdropColor: backdropColor, outlineWidth: outlineWidth)
                    
                    HStack {
                        HStack(spacing: 4) {
                            Text("Súng:")
                                .font(.caption2)
                                .foregroundColor(theme.secondaryText)
                            Circle().fill(gunColor).frame(width: 8, height: 8)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Text("Mảng Nền:")
                                .font(.caption2)
                                .foregroundColor(theme.secondaryText)
                            Circle().fill(backdropColor).frame(width: 8, height: 8)
                        }
                        Spacer()
                        Text("Dày: \(String(format: "%.1f px", outlineWidth))")
                            .font(.caption2)
                            .foregroundColor(theme.secondaryText)
                    }
                    .padding(.horizontal, 8)
                }
                .padding()
                .background(theme.cardBackground)
                .cornerRadius(24)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(theme.cardBorder, lineWidth: 1))
                
                // MARK: - Bước 2: Phối Màu Súng & Nền
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .foregroundColor(theme.accentColor)
                        Text(loc.t("gun_step2"))
                            .font(.headline)
                            .foregroundColor(theme.primaryText)
                        Spacer()
                    }
                    
                    // Combos 1-Chạm Hot
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phối Màu Đề Xuất (1-Chạm)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(theme.primaryText)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            comboButton(title: "Chuẩn Ảnh (Vàng + Trắng)", gun: .yellow, back: .white)
                            comboButton(title: "Lửa Rực (Đỏ + Trắng)", gun: .red, back: .white)
                            comboButton(title: "Cyber Neon (Xanh + Trắng)", gun: .cyan, back: .white)
                            comboButton(title: "Toxic (Lá + Trắng)", gun: .green, back: .white)
                            comboButton(title: "Huyền Bí (Tím + Trắng)", gun: .purple, back: .white)
                            comboButton(title: "Shadow (Vàng + Đen)", gun: .yellow, back: Color(red: 0.05, green: 0.05, blue: 0.05))
                        }
                    }
                    
                    Divider().background(theme.primaryText.opacity(0.1))
                    
                    // Color Pickers
                    VStack(spacing: 12) {
                        ColorPicker("Màu Thân Súng (Vị trí 1)", selection: $gunColor)
                            .foregroundColor(theme.primaryText)
                        ColorPicker("Màu Mảng Nền Poster (Vị trí 2)", selection: $backdropColor)
                            .foregroundColor(theme.primaryText)
                    }
                    
                    // Width Slider
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(loc.t("gun_width"))
                                .font(.subheadline)
                                .foregroundColor(theme.primaryText)
                            Spacer()
                            Text(String(format: "%.1f px", outlineWidth))
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(theme.accentColor)
                        }
                        Slider(value: $outlineWidth, in: 0.5...8.0, step: 0.5)
                            .accentColor(.cyan)
                    }
                }
                .padding()
                .background(theme.cardBackground)
                .cornerRadius(24)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(theme.cardBorder, lineWidth: 1))
                
                StudioPanel("Tạo bản dựng", icon: "arrow.down.doc") {
                    Button { buildAndExportGun(mode: "mod") } label: {
                        Label(isProcessing ? "Đang tạo bản dựng…" : "Tạo & xuất Shader", systemImage: "arrow.down.doc")
                    }.buttonStyle(StudioActionStyle()).disabled(isProcessing)
                    Button(action: injectGunToGame) { Label("Cài vào game", systemImage: "square.and.arrow.down") }
                        .buttonStyle(StudioActionStyle(secondary: true)).disabled(isProcessing)
                    Button { buildAndExportGun(mode: "goc") } label: {
                        Label("Khôi phục Shader gốc", systemImage: "arrow.counterclockwise").frame(minHeight: 44)
                    }.disabled(isProcessing)
                }
            }
            .padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom) { if isProcessing { StudioBusyBar(text: "Đang tạo bản dựng Shader…") } }
        .background(theme.backgroundColor)
        .navigationTitle("Shader Studio")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Thông Báo"), message: Text(alertMessage), dismissButton: .default(Text("Xác Nhận")))
        }
    }
    
    private func gameCoverImage(for ver: GameVersion) -> Image {
        let pngName = ver == .fft ? "game_icon_fft" : "game_icon_ffm"
        if let uiImg = UIImage(named: pngName) ?? (Bundle.main.path(forResource: pngName, ofType: "png").flatMap { UIImage(contentsOfFile: $0) }) {
            return Image(uiImage: uiImg)
        }
        let fallback = ver == .fft ? "game_cover_fft" : "game_cover_ffm"
        if let uiImg = UIImage(named: fallback) ?? (Bundle.main.path(forResource: fallback, ofType: "jpg").flatMap { UIImage(contentsOfFile: $0) }) {
            return Image(uiImage: uiImg)
        }
        return Image(systemName: "gamecontroller.fill")
    }
    
    private func comboButton(title: String, gun: Color, back: Color) -> some View {
        Button(action: {
            gunColor = gun
            backdropColor = back
        }) {
            HStack(spacing: 8) {
                HStack(spacing: 2) {
                    Circle().fill(gun).frame(width: 10, height: 10)
                    Circle().fill(back).frame(width: 10, height: 10)
                }
                Text(title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.primaryText.opacity(0.04))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.primaryText.opacity(0.1), lineWidth: 1))
        }
    }
    
    private func getRGB(from color: Color) -> (Float, Float, Float) {
        let uiColor = UIColor(color)
        var r: CGFloat = 1
        var g: CGFloat = 1
        var b: CGFloat = 1
        var a: CGFloat = 1
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Float(r * 255.0), Float(g * 255.0), Float(b * 255.0))
    }
    
    // MARK: - Build & Export via VPS API with Security Gatekeeper
    private func buildAndExportGun(mode: String) {
        isProcessing = true
        apiService.verifyGatekeeper { allowed, reason in
            if !allowed {
                isProcessing = false
                alertMessage = "LỖI BẢO MẬT:\n\(reason)"
                showAlert = true
                if !apiService.isAuthenticated {
                    showLoginSheet = true
                }
                return
            }
            
            if !apiService.isVIP {
                isProcessing = false
                alertMessage = "Tính năng tùy biến Shader chỉ dành cho tài khoản VIP!\nVui lòng liên hệ Admin để được cấp quyền VIP."
                showAlert = true
                return
            }
            
            let gunRGB = getRGB(from: gunColor)
            let backRGB = getRGB(from: backdropColor)
            
            apiService.buildGunShader(
                version: selectedVersion.rawValue,
                mode: mode,
                outlineRGB: [gunRGB.0, gunRGB.1, gunRGB.2, 1.0],
                xrayRGB: [backRGB.0, backRGB.1, backRGB.2, 1.0],
                width: outlineWidth
            ) { result in
                isProcessing = false
                switch result {
                case .success(let res):
                    if let url = GameInjector.shared.saveTempFile(data: res.data, filename: res.filename) {
                        GameInjector.shared.presentShareSheet(fileURL: url)
                    }
                case .failure(let err):
                    alertMessage = "Lỗi tạo file qua API: \(err.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func injectGunToGame() {
        isProcessing = true
        apiService.verifyGatekeeper { allowed, reason in
            if !allowed {
                isProcessing = false
                alertMessage = "LỖI BẢO MẬT:\n\(reason)"
                showAlert = true
                if !apiService.isAuthenticated {
                    showLoginSheet = true
                }
                return
            }
            
            if !apiService.isVIP {
                isProcessing = false
                alertMessage = "Tính năng tùy biến Shader chỉ dành cho tài khoản VIP!\nVui lòng liên hệ Admin để được cấp quyền VIP."
                showAlert = true
                return
            }
            
            let gunRGB = getRGB(from: gunColor)
            let backRGB = getRGB(from: backdropColor)
            
            apiService.buildGunShader(
                version: selectedVersion.rawValue,
                mode: "mod",
                outlineRGB: [gunRGB.0, gunRGB.1, gunRGB.2, 1.0],
                xrayRGB: [backRGB.0, backRGB.1, backRGB.2, 1.0],
                width: outlineWidth
            ) { result in
                switch result {
                case .success(let res):
                    GameInjector.shared.injectShaderFile(data: res.data, filename: res.filename, version: selectedVersion) { success, msg in
                        isProcessing = false
                        alertMessage = msg
                        showAlert = true
                    }
                case .failure(let err):
                    isProcessing = false
                    alertMessage = "Lỗi: \(err.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}
