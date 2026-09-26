import SwiftUI
import UniformTypeIdentifiers
import UIKit

// MARK: - Native Document Picker Manager (Full-Screen UIKit presentation bypasses SwiftUI sheet bugs & permission errors)
public final class DocumentPickerManager: NSObject, UIDocumentPickerDelegate {
    public static let shared = DocumentPickerManager()
    
    private var onPickCompletion: ((URL, Data) -> Void)?
    private var onErrorCompletion: ((String) -> Void)?
    
    private override init() {
        super.init()
    }
    
    public func pickFile(
        onPick: @escaping (URL, Data) -> Void,
        onError: @escaping (String) -> Void
    ) {
        self.onPickCompletion = onPick
        self.onErrorCompletion = onError
        
        DispatchQueue.main.async {
            guard let topVC = self.getTopViewController() else {
                onError("Không thể mở trình duyệt tệp trên màn hình hiện tại.")
                return
            }
            
            var types: [UTType] = [.item, .data, .content, .archive, .plainText]
            if let customType = UTType(filenameExtension: "GkLlYqzsX4AtTdE55sDMRh9sJOI~3D") {
                types.append(customType)
            }
            if let legacyType = UTType(filenameExtension: "CfnFf59sr1SbsqQ6JqTKsEusjKs~3D") {
                types.append(legacyType)
            }
            
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
            picker.delegate = self
            picker.allowsMultipleSelection = false
            picker.shouldShowFileExtensions = true
            picker.modalPresentationStyle = .fullScreen
            
            topVC.present(picker, animated: true, completion: nil)
        }
    }
    
    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            return UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
        }
        var top = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController ?? windowScene.windows.first?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let pickedURL = urls.first else {
            onErrorCompletion?("Không có tệp nào được chọn.")
            return
        }
        
        let accessed = pickedURL.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                pickedURL.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let data = try Data(contentsOf: pickedURL)
            
            // Copy to local app Documents folder so it persists locally
            if let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let localURL = docDir.appendingPathComponent(pickedURL.lastPathComponent)
                try? data.write(to: localURL)
            }
            
            onPickCompletion?(pickedURL, data)
        } catch {
            onErrorCompletion?("Lỗi đọc dữ liệu tệp: \(error.localizedDescription)")
        }
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // User cancelled
    }
}

// MARK: - Local App Cache File Model
public struct LocalAppCacheFile: Identifiable {
    public let id = UUID()
    public let name: String
    public let size: Int
    public let url: URL
    public let date: Date
}

// MARK: - Main HitboxModView (Brand New 2026 Cyberpunk VIP GUI)
public struct HitboxModView: View {
    @ObservedObject var api = APIService.shared
    @ObservedObject var loc = LocalizationManager.shared
    @ObservedObject var theme = ThemeManager.shared
    
    // Cache Source State
    @State private var userCacheData: Data? = nil
    @State private var userCacheFileName: String = "cache_res.GkLlYqzsX4AtTdE55sDMRh9sJOI~3D (Mặc Định Gốc)"
    @State private var userCacheFileSize: Int = 63056
    @State private var cacheSourceType: String = "server" // "server", "file", "game"
    
    // Local app documents cache files
    @State private var localFiles: [LocalAppCacheFile] = []
    @State private var showLocalFilesList: Bool = false
    
    @State private var selectedVersion: GameVersion = .fft
    @State private var selectedPresetId: String = "cheast"
    
    // Coordinate Tuning State
    @State private var maleHeadRadius: Float = 0.058863
    @State private var maleHeadCenterX: Float = 0.035773
    @State private var maleHeadCenterY: Float = 0.0
    
    @State private var femaleHeadRadius: Float = 0.058863
    @State private var femaleHeadCenterX: Float = 0.035773
    @State private var femaleHeadCenterY: Float = 0.0
    
    @State private var maleSpineRadius: Float = 0.070349
    @State private var maleSpineHeight: Float = 0.070349
    
    @State private var femaleSpineRadius: Float = 0.070349
    @State private var femaleSpineHeight: Float = 0.070349
    
    @State private var syncGender: Bool = true
    @State private var activeTab: String = "head"
    
    @State private var isProcessing: Bool = false
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var showLoginSheet: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            theme.backgroundColor.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    
                    // 1. HERO CYBER STATUS BANNER
                    heroCyberBanner
                    
                    // 2. GAME VERSION SELECTOR (FFT vs FFM)
                    gameVersionSelectorSection
                    
                    // 3. CACHE SOURCE MANAGER (3 MODES + LOCAL SCANNER)
                    cacheSourceManagerSection
                    
                    // 4. LIVE HITBOX PREVIEW CANVAS
                    liveHitboxCanvasSection
                    
                    // 5. 1-TAP QUICK PRESETS
                    quickPresetsSection
                    
                    // 6. FINE-TUNING CONTROLLER (SLIDERS WITH STEPPERS)
                    fineTuningSlidersSection
                    
                    // 7. BOTTOM ACTION HUB
                    bottomActionHubSection
                    
                    Spacer().frame(height: 28)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .background(theme.backgroundColor)
        .navigationTitle("Cache_res")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshLocalFiles()
            if let firstPreset = HitboxConfig.defaultPresets.first {
                applyPreset(firstPreset)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Thông Báo Hệ Thống"),
                message: Text(alertMessage),
                dismissButton: .default(Text("Đã Hiểu"))
            )
        }
    }
    
    // MARK: - 1. Hero Cyber Status Banner
    private var heroCyberBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cyan.opacity(0.35), Color.clear],
                            center: .center,
                            startRadius: 2,
                            endRadius: 24
                        )
                    )
                    .frame(width: 46, height: 46)
                
                Image(systemName: "cpu.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.neonCyan)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Cache_res")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(theme.primaryText)
                    
                    // Icon Pre (Premium VIP badge)
                    HStack(spacing: 3) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.yellow)
                        Text("PRE")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(Color.yellow.opacity(0.18))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.yellow.opacity(0.4), lineWidth: 1))
                }
                
                Text("MeoMeoCheat")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(theme.secondaryText)
            }
            
            Spacer()
            
            // Server status indicator pill
            HStack(spacing: 5) {
                Circle()
                    .fill(api.isOnline ? Color.green : Color.red)
                    .frame(width: 7, height: 7)
                Text(api.isOnline ? "ONLINE" : "OFFLINE")
                    .font(.system(size: 9, weight: .heavy))
                    .foregroundColor(api.isOnline ? .green : .red)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.06))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.14, blue: 0.24), Color(red: 0.08, green: 0.10, blue: 0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.cyan.opacity(0.25), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
    }
    
    // MARK: - 2. Game Version Selector
    private var gameVersionSelectorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "gamecontroller.fill")
                    .foregroundColor(theme.neonCyan)
                Text("Phiên Bản Free Fire Mục Tiêu")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(theme.primaryText)
                Spacer()
            }
            
            HStack(spacing: 12) {
                ForEach(GameVersion.allCases) { ver in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedVersion = ver
                        }
                    }) {
                        HStack(spacing: 10) {
                            gameAppStoreIcon(for: ver)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 42, height: 42)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ver == .fft ? "FF Thường" : "FF MAX")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(selectedVersion == ver ? theme.neonCyan : theme.primaryText)
                                Text(ver == .fft ? "com.dts.freefireth" : "com.dts.freefiremax")
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundColor(theme.secondaryText)
                                    .lineLimit(1)
                            }
                            Spacer()
                            if selectedVersion == ver {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(theme.neonCyan)
                                    .font(.system(size: 16))
                            }
                        }
                        .padding(10)
                        .background(selectedVersion == ver ? theme.neonCyan.opacity(0.12) : Color.white.opacity(0.04))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selectedVersion == ver ? theme.neonCyan : Color.white.opacity(0.08), lineWidth: 1.2)
                        )
                    }
                }
            }
        }
        .padding(14)
        .background(theme.cardBackground)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(theme.cardBorder, lineWidth: 1))
    }
    
    // MARK: - 3. Cache Source Manager (Comprehensive Fix: Native Full-Screen Picker + Direct Game Scan + Local Documents)
    private var cacheSourceManagerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "internaldrive.fill")
                    .foregroundColor(theme.neonCyan)
                Text("Nguồn File Cache Mục Tiêu (cache_res)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(theme.primaryText)
                Spacer()
                
                // Active status tag
                HStack(spacing: 4) {
                    Circle()
                        .fill(cacheSourceType == "server" ? Color.cyan : Color.green)
                        .frame(width: 6, height: 6)
                    Text(cacheSourceType == "server" ? "MÁY CHỦ GỐC" : (cacheSourceType == "game" ? "TRỰC TIẾP GAME" : "TỆP THIẾT BỊ"))
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(cacheSourceType == "server" ? .cyan : .green)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(cacheSourceType == "server" ? Color.cyan.opacity(0.15) : Color.green.opacity(0.15))
                .clipShape(Capsule())
            }
            
            // Current Loaded File Card
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(userCacheData != nil ? Color.green.opacity(0.15) : Color.cyan.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: userCacheData != nil ? "doc.badge.gearshape.fill" : "server.rack")
                        .font(.system(size: 17))
                        .foregroundColor(userCacheData != nil ? .green : theme.neonCyan)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(userCacheFileName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(theme.primaryText)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text("\(userCacheFileSize) Bytes")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(userCacheData != nil ? .green : theme.secondaryText)
                        Text("•")
                            .font(.system(size: 8))
                            .foregroundColor(theme.secondaryText)
                        Text(userCacheData != nil ? "Đã nạp vào bộ nhớ" : "Sẵn sàng build từ máy chủ")
                            .font(.system(size: 10))
                            .foregroundColor(theme.secondaryText)
                    }
                }
                
                Spacer()
                
                if userCacheData != nil {
                    Button(action: {
                        resetToDefaultServerBase()
                    }) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(11)
            .background(Color.white.opacity(0.04))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(userCacheData != nil ? Color.green.opacity(0.4) : Color.cyan.opacity(0.25), lineWidth: 1)
            )
            
            // 3 Source Selector Action Buttons
            HStack(spacing: 8) {
                // Button 1: Default Official Server Base
                Button(action: {
                    resetToDefaultServerBase()
                    alertMessage = "Đã chọn: File Cache Gốc Chuẩn từ máy chủ.\nBạn có thể nhấn 'Build File' ngay mà không cần tải tệp từ thiết bị!"
                    showAlert = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "cloud.fill")
                            .font(.system(size: 14))
                        Text("Mặc Định Gốc")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(cacheSourceType == "server" ? Color.cyan.opacity(0.25) : Color.cyan.opacity(0.08))
                    .foregroundColor(.cyan)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.cyan.opacity(cacheSourceType == "server" ? 0.7 : 0.25), lineWidth: 1.2)
                    )
                }
                
                // Button 2: Native Full-Screen Document Picker (Picks ANY file from iPhone)
                Button(action: {
                    openNativeDocumentPicker()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 14))
                        Text("Chọn Từ Tệp")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(cacheSourceType == "file" ? Color.blue.opacity(0.25) : Color.blue.opacity(0.08))
                    .foregroundColor(.blue)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue.opacity(cacheSourceType == "file" ? 0.7 : 0.25), lineWidth: 1.2)
                    )
                }
                
                // Button 3: Auto-Extract directly from Game (TrollStore / JB)
                Button(action: {
                    extractCacheFromGameDirectly()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "bolt.horizontal.fill")
                            .font(.system(size: 14))
                        Text("Lấy Từ Game")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(cacheSourceType == "game" ? Color.purple.opacity(0.25) : Color.purple.opacity(0.08))
                    .foregroundColor(.purple)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.purple.opacity(cacheSourceType == "game" ? 0.7 : 0.25), lineWidth: 1.2)
                    )
                }
            }
            
            // Optional: Local Files found in App Documents Directory ("Trên iPhone > Reg Mod")
            if !localFiles.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "tray.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                        Text("Tệp có sẵn trong thư mục app 'Build File' (\(localFiles.count))")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(theme.primaryText)
                        Spacer()
                        Button(action: {
                            withAnimation { showLocalFilesList.toggle() }
                        }) {
                            Text(showLocalFilesList ? "Thu gọn" : "Xem")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.orange)
                        }
                    }
                    
                    if showLocalFilesList {
                        VStack(spacing: 6) {
                            ForEach(localFiles) { file in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(file.name)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(theme.primaryText)
                                            .lineLimit(1)
                                        Text("\(file.size) bytes")
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(theme.secondaryText)
                                    }
                                    Spacer()
                                    Button(action: {
                                        loadLocalAppFile(file)
                                    }) {
                                        Text("Nạp")
                                            .font(.system(size: 10, weight: .heavy))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.orange.opacity(0.2))
                                            .foregroundColor(.orange)
                                            .clipShape(Capsule())
                                    }
                                }
                                .padding(8)
                                .background(Color.white.opacity(0.03))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(10)
                .background(Color.orange.opacity(0.05))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.orange.opacity(0.2), lineWidth: 1))
            }
        }
        .padding(14)
        .background(theme.cardBackground)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(theme.cardBorder, lineWidth: 1))
    }
    
    // MARK: - 4. Live Hitbox Canvas Section
    private var liveHitboxCanvasSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "viewfinder")
                    .foregroundColor(.purple)
                Text("Mô Phỏng Hitbox Trực Quan")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(theme.primaryText)
                Spacer()
                
                Text("Vùng Trúng Đạn")
                    .font(.system(size: 10))
                    .foregroundColor(theme.secondaryText)
            }
            
            HitboxPreviewCanvas(
                headRadius: maleHeadRadius,
                headCenterX: maleHeadCenterX,
                headCenterY: maleHeadCenterY,
                spineRadius: maleSpineRadius,
                spineHeight: maleSpineHeight
            )
        }
        .padding(14)
        .background(theme.cardBackground)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(theme.cardBorder, lineWidth: 1))
    }
    
    // MARK: - 5. Quick Presets Section
    private var quickPresetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 14))
                    .foregroundColor(.purple)
                Text("Công Thức 1-Chạm (Presets)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(theme.primaryText)
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(HitboxConfig.defaultPresets) { preset in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            applyPreset(preset)
                        }
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(presetBadgeColor(for: preset.id).opacity(0.15))
                                    .frame(width: 38, height: 38)
                                Image(systemName: presetIcon(for: preset.id))
                                    .font(.headline)
                                    .foregroundColor(presetBadgeColor(for: preset.id))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(preset.title)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(selectedPresetId == preset.id ? theme.neonCyan : theme.primaryText)
                                    Spacer()
                                    if selectedPresetId == preset.id {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(theme.neonCyan)
                                            .font(.system(size: 14))
                                    }
                                }
                                Text(preset.desc)
                                    .font(.system(size: 10))
                                    .foregroundColor(theme.secondaryText)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedPresetId == preset.id ? theme.neonCyan.opacity(0.08) : Color.white.opacity(0.03))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedPresetId == preset.id ? theme.neonCyan.opacity(0.6) : Color.clear, lineWidth: 1)
                        )
                    }
                }
            }
        }
        .padding(14)
        .background(theme.cardBackground)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(theme.cardBorder, lineWidth: 1))
    }
    
    // MARK: - 6. Fine-Tuning Sliders Section
    private var fineTuningSlidersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(theme.neonCyan)
                Text("Tinh Chỉnh Tọa Độ Nhị Phân")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(theme.primaryText)
                Spacer()
                Toggle("", isOn: $syncGender)
                    .labelsHidden()
                Text("Đồng bộ")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(theme.secondaryText)
            }
            
            Picker("", selection: $activeTab) {
                Text("Đầu (bone_Head)").tag("head")
                Text("Thân / Magic (bone_Spine)").tag("spine")
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if activeTab == "head" {
                VStack(spacing: 12) {
                    sliderRow(title: "Bán kính đầu (Radius)", value: $maleHeadRadius, range: 0.03...0.30, unit: "m", step: 0.005) { val in
                        selectedPresetId = "custom"
                        if syncGender { femaleHeadRadius = val }
                    }
                    sliderRow(title: "Trục X (Kéo Cổ / Bụng)", value: $maleHeadCenterX, range: -0.10...0.20, unit: "m", step: 0.005) { val in
                        selectedPresetId = "custom"
                        if syncGender { femaleHeadCenterX = val }
                    }
                    sliderRow(title: "Trục Y (Độ lệch Y)", value: $maleHeadCenterY, range: -0.05...0.05, unit: "m", step: 0.002) { val in
                        selectedPresetId = "custom"
                        if syncGender { femaleHeadCenterY = val }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    sliderRow(title: "Bán kính thân (Spine Radius)", value: $maleSpineRadius, range: 0.05...2.0, unit: "m", step: 0.05) { val in
                        selectedPresetId = "custom"
                        if syncGender { femaleSpineRadius = val }
                    }
                    sliderRow(title: "Chiều cao thân (Spine Height)", value: $maleSpineHeight, range: 0.05...2.0, unit: "m", step: 0.05) { val in
                        selectedPresetId = "custom"
                        if syncGender { femaleSpineHeight = val }
                    }
                }
            }
        }
        .padding(14)
        .background(theme.cardBackground)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(theme.cardBorder, lineWidth: 1))
    }
    
    // MARK: - 7. Bottom Action Hub
    private var bottomActionHubSection: some View {
        VStack(spacing: 12) {
            if !api.canMakeCache {
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                    Text("Tính năng tạo Cache miễn phí hiện đang tạm đóng bởi Quản trị viên! Vui lòng nâng cấp VIP hoặc liên hệ Admin.")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.red)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.12))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.3), lineWidth: 1))
            }
            
            Button(action: {
                buildAndExportCache()
            }) {
                HStack(spacing: 10) {
                    if isProcessing {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("BUILDING FILE...")
                            .font(.system(size: 15, weight: .black))
                    } else {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.yellow)
                        Text("BUILD FILE (PRE)")
                            .font(.system(size: 15, weight: .black))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.0, green: 0.85, blue: 1.0), Color(red: 0.6, green: 0.2, blue: 1.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: Color.cyan.opacity(0.4), radius: 10, y: 5)
            }
            .disabled(isProcessing)
            
            Button(action: {
                injectCacheToGame()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 16))
                    Text("CÀI ĐẶT FILE VÀO GAME (DOCUMENTS)")
                        .font(.system(size: 13, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.05))
                .foregroundColor(theme.neonCyan)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(theme.neonCyan.opacity(0.4), lineWidth: 1.2)
                )
            }
            .disabled(isProcessing)
            
            // Small guide tip
            Text("💡 Gợi ý: Với TrollStore/Jailbreak, chọn 'Cài đặt file'. Với Scarlet/E-Sign, bấm 'Build File' rồi chọn 'Lưu vào Tệp'.")
                .font(.system(size: 10))
                .foregroundColor(theme.secondaryText.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
        }
    }
    
    // MARK: - Helper UI Builders
    private func presetBadgeColor(for id: String) -> Color {
        switch id {
        case "headshot": return .purple
        case "magic": return .cyan
        case "body": return .green
        default: return .orange
        }
    }
    
    private func presetIcon(for id: String) -> String {
        switch id {
        case "headshot": return "scope"
        case "magic": return "wand.and.stars"
        case "body": return "shield.fill"
        default: return "slider.horizontal.3"
        }
    }
    
    private func sliderRow(title: String, value: Binding<Float>, range: ClosedRange<Float>, unit: String, step: Float = 0.005, onChange: @escaping (Float) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.secondaryText)
                Spacer()
                Text("\(String(format: "%.4f", value.wrappedValue)) \(unit)")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.cyan.opacity(0.15))
                    .foregroundColor(.cyan)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.cyan.opacity(0.3), lineWidth: 1))
            }
            
            HStack(spacing: 10) {
                Button(action: {
                    let newVal = max(range.lowerBound, value.wrappedValue - step)
                    value.wrappedValue = newVal
                    onChange(newVal)
                }) {
                    Image(systemName: "minus")
                        .font(.caption2)
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(theme.primaryText)
                        .clipShape(Circle())
                }
                
                Slider(value: Binding(
                    get: { value.wrappedValue },
                    set: {
                        value.wrappedValue = $0
                        onChange($0)
                    }
                ), in: range)
                .accentColor(theme.neonCyan)
                
                Button(action: {
                    let newVal = min(range.upperBound, value.wrappedValue + step)
                    value.wrappedValue = newVal
                    onChange(newVal)
                }) {
                    Image(systemName: "plus")
                        .font(.caption2)
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(theme.primaryText)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Cache Source Logic Implementation
    private func resetToDefaultServerBase() {
        userCacheData = nil
        userCacheFileName = "cache_res.GkLlYqzsX4AtTdE55sDMRh9sJOI~3D (Mặc Định Gốc)"
        userCacheFileSize = 63056
        cacheSourceType = "server"
    }
    
    private func openNativeDocumentPicker() {
        DocumentPickerManager.shared.pickFile(
            onPick: { url, data in
                self.userCacheData = data
                self.userCacheFileName = url.lastPathComponent
                self.userCacheFileSize = data.count
                self.cacheSourceType = "file"
                self.refreshLocalFiles()
                self.alertMessage = "Đã nhận thành công tệp '\(url.lastPathComponent)' (\(data.count) Bytes) từ thiết bị!\nSẵn sàng để build file qua Server API."
                self.showAlert = true
            },
            onError: { errMsg in
                self.alertMessage = errMsg
                self.showAlert = true
            }
        )
    }
    
    private func extractCacheFromGameDirectly() {
        let res = GameInjector.shared.readCacheFromGame(version: selectedVersion)
        if let d = res.data, let fName = res.actualFilename {
            userCacheData = d
            userCacheFileName = fName
            userCacheFileSize = d.count
            cacheSourceType = "game"
            refreshLocalFiles()
            alertMessage = res.message
            showAlert = true
        } else {
            alertMessage = res.message
            showAlert = true
        }
    }
    
    private func refreshLocalFiles() {
        guard let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: docDir, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey])
            self.localFiles = urls.compactMap { u -> LocalAppCacheFile? in
                let fname = u.lastPathComponent
                guard fname.contains("cache") || fname.contains("res") || fname.contains("GkLlYqzs") || fname.contains("CfnFf59sr1") else { return nil }
                let attrs = (try? FileManager.default.attributesOfItem(atPath: u.path)) ?? [:]
                let size = attrs[.size] as? Int ?? 0
                let date = attrs[.modificationDate] as? Date ?? Date()
                return LocalAppCacheFile(name: fname, size: size, url: u, date: date)
            }
        } catch {
            self.localFiles = []
        }
    }
    
    private func loadLocalAppFile(_ file: LocalAppCacheFile) {
        if let d = try? Data(contentsOf: file.url) {
            userCacheData = d
            userCacheFileName = file.name
            userCacheFileSize = d.count
            cacheSourceType = "file"
            alertMessage = "Đã nạp tệp '\(file.name)' (\(d.count) Bytes) từ thư mục Documents của app!"
            showAlert = true
        }
    }
    
    private func applyPreset(_ preset: HitboxPreset) {
        selectedPresetId = preset.id
        
        switch preset.id {
        case "nhe_tam":
            maleHeadRadius = 0.099059
            maleHeadCenterX = 0.055245
            maleHeadCenterY = 0.017060
            femaleHeadRadius = 0.099154
            femaleHeadCenterX = 0.050775
            femaleHeadCenterY = 0.000020
            maleSpineRadius = 0.070
            maleSpineHeight = 0.180
            femaleSpineRadius = 0.070
            femaleSpineHeight = 0.170
        case "cheast":
            maleHeadRadius = 0.099089
            maleHeadCenterX = -0.010615
            maleHeadCenterY = 0.017060
            femaleHeadRadius = 0.099136
            femaleHeadCenterX = -0.010934
            femaleHeadCenterY = 0.000020
            maleSpineRadius = 0.070
            maleSpineHeight = 0.180
            femaleSpineRadius = 0.070
            femaleSpineHeight = 0.170
        case "body":
            maleHeadRadius = 0.099038
            maleHeadCenterX = 0.121035
            maleHeadCenterY = 0.020093
            femaleHeadRadius = 0.099033
            femaleHeadCenterX = 0.120743
            femaleHeadCenterY = 0.017238
            maleSpineRadius = 0.070
            maleSpineHeight = 0.180
            femaleSpineRadius = 0.070
            femaleSpineHeight = 0.170
        case "sniper_hitbox":
            maleHeadRadius = 0.059059
            maleHeadCenterX = -0.045245
            maleHeadCenterY = 0.017060
            femaleHeadRadius = 0.059154
            femaleHeadCenterX = -0.040775
            femaleHeadCenterY = 0.000020
            maleSpineRadius = 0.070
            maleSpineHeight = 0.180
            femaleSpineRadius = 0.070
            femaleSpineHeight = 0.170
        case "magic", "super_magic":
            maleHeadRadius = 0.059059
            maleHeadCenterX = -0.045245
            maleHeadCenterY = 0.017060
            femaleHeadRadius = 0.059154
            femaleHeadCenterX = -0.040775
            femaleHeadCenterY = 0.000020
            maleSpineRadius = 1.070349
            maleSpineHeight = 1.070349
            femaleSpineRadius = 1.070349
            femaleSpineHeight = 1.070349
        case "combo_cheast_magic":
            maleHeadRadius = 0.099089
            maleHeadCenterX = -0.010615
            maleHeadCenterY = 0.017060
            femaleHeadRadius = 0.099136
            femaleHeadCenterX = -0.010934
            femaleHeadCenterY = 0.000020
            maleSpineRadius = 1.070349
            maleSpineHeight = 1.070349
            femaleSpineRadius = 1.070349
            femaleSpineHeight = 1.070349
        default:
            maleHeadRadius = 0.059059
            maleHeadCenterX = -0.045245
            maleHeadCenterY = 0.01706
            femaleHeadRadius = 0.059154
            femaleHeadCenterX = -0.040775
            femaleHeadCenterY = 0.00002
            maleSpineRadius = 0.070294
            maleSpineHeight = 0.179913
            femaleSpineRadius = 0.070290
            femaleSpineHeight = 0.170000
        }
    }
    
    // MARK: - Build and Export Cache via 100% Server API
    private func buildAndExportCache() {
        if !api.canMakeCache {
            alertMessage = "TẠM ĐÓNG TÍNH NĂNG:\nTính năng tạo Cache miễn phí hiện đang tạm đóng bởi Quản trị viên! Vui lòng liên hệ Admin MeoNxt để nâng cấp gói VIP."
            showAlert = true
            return
        }
        
        isProcessing = true
        api.verifyGatekeeper { allowed, reason in
            if !allowed {
                isProcessing = false
                alertMessage = "LỖI BẢO MẬT:\n\(reason)"
                showAlert = true
                if !api.isAuthenticated {
                    showLoginSheet = true
                }
                return
            }
            
            let exportFilename = (userCacheFileName.isEmpty || userCacheFileName.contains("Mặc Định")) ? "cache_res.GkLlYqzsX4AtTdE55sDMRh9sJOI~3D" : userCacheFileName
            
            api.buildHitboxCache(
                presetId: selectedPresetId,
                maleHeadRadius: maleHeadRadius,
                maleHeadCenterX: maleHeadCenterX,
                maleHeadCenterY: maleHeadCenterY,
                femaleHeadRadius: femaleHeadRadius,
                femaleHeadCenterX: femaleHeadCenterX,
                femaleHeadCenterY: femaleHeadCenterY,
                maleSpineRadius: maleSpineRadius,
                maleSpineHeight: maleSpineHeight,
                femaleSpineRadius: femaleSpineRadius,
                femaleSpineHeight: femaleSpineHeight,
                customBaseData: userCacheData
            ) { result in
                isProcessing = false
                switch result {
                case .success(let data):
                    if let url = GameInjector.shared.saveTempFile(data: data, filename: exportFilename) {
                        GameInjector.shared.presentShareSheet(fileURL: url)
                    }
                case .failure(let err):
                    alertMessage = "Lỗi tạo Cache qua API: \(err.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func injectCacheToGame() {
        if !api.canMakeCache {
            alertMessage = "TẠM ĐÓNG TÍNH NĂNG:\nTính năng tạo Cache miễn phí hiện đang tạm đóng bởi Quản trị viên! Vui lòng liên hệ Admin MeoNxt để nâng cấp gói VIP."
            showAlert = true
            return
        }
        
        isProcessing = true
        api.verifyGatekeeper { allowed, reason in
            if !allowed {
                isProcessing = false
                alertMessage = "LỖI BẢO MẬT:\n\(reason)"
                showAlert = true
                if !api.isAuthenticated {
                    showLoginSheet = true
                }
                return
            }
            
            let exportFilename = (userCacheFileName.isEmpty || userCacheFileName.contains("Mặc Định")) ? "cache_res.GkLlYqzsX4AtTdE55sDMRh9sJOI~3D" : userCacheFileName
            
            api.buildHitboxCache(
                presetId: selectedPresetId,
                maleHeadRadius: maleHeadRadius,
                maleHeadCenterX: maleHeadCenterX,
                maleHeadCenterY: maleHeadCenterY,
                femaleHeadRadius: femaleHeadRadius,
                femaleHeadCenterX: femaleHeadCenterX,
                femaleHeadCenterY: femaleHeadCenterY,
                maleSpineRadius: maleSpineRadius,
                maleSpineHeight: maleSpineHeight,
                femaleSpineRadius: femaleSpineRadius,
                femaleSpineHeight: femaleSpineHeight,
                customBaseData: userCacheData
            ) { result in
                switch result {
                case .success(let data):
                    GameInjector.shared.injectCacheFile(data: data, filename: exportFilename, version: selectedVersion) { success, msg in
                        isProcessing = false
                        alertMessage = msg
                        showAlert = true
                    }
                case .failure(let err):
                    isProcessing = false
                    alertMessage = "Lỗi tạo Cache qua API: \(err.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func gameAppStoreIcon(for ver: GameVersion) -> Image {
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
}
