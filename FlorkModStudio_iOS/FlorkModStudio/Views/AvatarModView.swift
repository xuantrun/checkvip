import SwiftUI

// MARK: - Avatar Preset Data Model
public struct AvatarPresetItem: Identifiable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let bone: String
    public let hash: Int
    public let defaultScale: Double
    public let icon: String
    public let color: Color
    public let isAntena: Bool
    public let posX: Double
    public let posY: Double
    public let posZ: Double
    public let rotX: Double
    public let rotY: Double
    public let rotZ: Double
    public let rotW: Double
}

public struct AvatarModView: View {
    @ObservedObject var api = APIService.shared
    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var loc = LocalizationManager.shared
    
    // Presets from dpi reference (templates/index.html & mod_clean.bundle)
    let presets: [AvatarPresetItem] = [
        AvatarPresetItem(
            id: "aimbot_head",
            title: "Aim Head (Đỉnh Đầu HS)",
            subtitle: "Khóa thẳng vào đầu (Headshot 100% - Chuẩn mod_clean)",
            bone: "bone_Head",
            hash: -1541408846,
            defaultScale: 1.5555556,
            icon: "target",
            color: .red,
            isAntena: false,
            posX: -0.044599998742341995,
            posY: -0.0038999998942017555,
            posZ: -5.960000049043401e-09,
            rotX: 0.006340285,
            rotY: 3.041255474090576,
            rotZ: -0.0370349,
            rotW: 0.9984419
        ),
        AvatarPresetItem(
            id: "aimbot_neck",
            title: "Aim Neck (Hạ Cổ HS)",
            subtitle: "Hạ cổ HS tránh giật tâm (Bắn cổ ra Headshot)",
            bone: "bone_Head",
            hash: -1541408846,
            defaultScale: 1.5555556,
            icon: "viewfinder.circle",
            color: .cyan,
            isAntena: false,
            posX: -0.044599998742341995,
            posY: -0.0038999998942017555,
            posZ: -5.960000049043401e-09,
            rotX: 0.006340285,
            rotY: 3.041255474090576,
            rotZ: -0.0370349,
            rotW: 0.9984419
        ),
        AvatarPresetItem(
            id: "aim_body_all_hs",
            title: "Aim Body All ➔ Headshot",
            subtitle: "Bắn Thân ra HS 100% (bone_Spine giữa ngực)",
            bone: "bone_Spine",
            hash: 1529948125,
            defaultScale: 2.00,
            icon: "flame.fill",
            color: .red,
            isAntena: false,
            posX: -0.044599998742341995,
            posY: -0.0038999998942017555,
            posZ: -5.960000049043401e-09,
            rotX: 0.006340285,
            rotY: 3.041255474090576,
            rotZ: -0.0370349,
            rotW: 0.9984419
        ),
        AvatarPresetItem(
            id: "aim_hips_hs",
            title: "Aim Hông ➔ Headshot",
            subtitle: "Bắn Hông / Bụng dưới ra Headshot 100%",
            bone: "bone_Hips",
            hash: 2018908708,
            defaultScale: 2.00,
            icon: "circle.grid.cross.fill",
            color: .orange,
            isAntena: false,
            posX: -0.044599998742341995,
            posY: -0.0038999998942017555,
            posZ: -5.960000049043401e-09,
            rotX: 0.006340285,
            rotY: 3.041255474090576,
            rotZ: -0.0370349,
            rotW: 0.9984419
        ),
        AvatarPresetItem(
            id: "aim_body_spine",
            title: "Aim Body Thường",
            subtitle: "Mở rộng Hitbox Thân không HS (bone_Spine)",
            bone: "bone_Spine",
            hash: 1529948125,
            defaultScale: 1.60,
            icon: "shield.fill",
            color: .green,
            isAntena: false,
            posX: -0.04798,
            posY: -0.00025,
            posZ: 0.0,
            rotX: 0.0,
            rotY: 0.0,
            rotZ: -0.000398,
            rotW: 1.0
        ),
        AvatarPresetItem(
            id: "antena",
            title: "Antena Avatar",
            subtitle: "Cột cờ đỉnh đầu định vị kẻ địch xuyên map",
            bone: "bone_Head",
            hash: -1541408846,
            defaultScale: 1.55554,
            icon: "antenna.radiowaves.left.and.right",
            color: .yellow,
            isAntena: true,
            posX: -0.3749083,
            posY: -0.0745993,
            posZ: -0.000002,
            rotX: 0.0,
            rotY: 2.6793561,
            rotZ: -0.000008,
            rotW: -0.000013
        ),
        AvatarPresetItem(
            id: "custom",
            title: "Tùy Chỉnh",
            subtitle: "Tự do cấu hình Bone, Scale & Tọa độ XYZ",
            bone: "bone_Head",
            hash: -1541408846,
            defaultScale: 1.55,
            icon: "slider.horizontal.3",
            color: .purple,
            isAntena: false,
            posX: -0.086620286,
            posY: 0.0,
            posZ: 0.0,
            rotX: 0.0,
            rotY: 0.0,
            rotZ: 0.11343982,
            rotW: 0.9935449
        )
    ]
    
    // State variables
    @State private var selectedPresetId: String = "aimbot_head"
    @State private var targetBone: String = "bone_Head"
    @State private var parentHash: Int = -1541408846
    @State private var scaleVal: Double = 1.5555556
    @State private var modMale: Bool = true
    @State private var modFemale: Bool = true
    @State private var modBigGun: Bool = false
    @State private var gunScale: Double = 3.5
    @State private var matchSize: Bool = true
    @State private var patchMono: Bool = true
    
    // Coordinate Tuning (Direct Position XYZ matching dpi)
    @State private var posX: Double = -0.1566203
    @State private var posY: Double = 0.0
    @State private var posZ: Double = 0.0
    @State private var rotX: Double = 0.0
    @State private var rotY: Double = -3.1463483e-07
    @State private var rotZ: Double = 0.11343982
    @State private var rotW: Double = 0.9935449
    
    // Custom file state
    @State private var customFileName: String? = nil
    @State private var customFileData: Data? = nil
    @State private var showFileImporter: Bool = false
    
    // Build & Execution State
    @State private var isBuilding: Bool = false
    @State private var builtData: Data? = nil
    @State private var builtFilename: String = "assetindexer.U6Zffc4YIR3DslNj3cXvYGAqz58~3D"
    @State private var appliedChanges: [String] = []
    @State private var selectedGame: GameVersion = .fft
    
    // Alerts
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    
    public init() {}
    
    private var activePreset: AvatarPresetItem {
        presets.first(where: { $0.id == selectedPresetId }) ?? presets[0]
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                // Header Banner
                headerBannerView
                
                // Server Status & VIP Pill
                serverStatusPill
                
                // 1. Game Version Selector (Shader-style Interactive Tap Feedback)
                gameVersionSelectorSection
                
                // 2. Preset Selector (Shader-style Interactive Tap Display)
                presetSelectorCard
                
                // 3. Live Avatar Simulation & Hitbox Check Canvas (Như Cache Mô Phỏng)
                liveAvatarHitboxCanvasCard
                
                // 4. XYZ Coordinate Tuning Sliders (Như Bên Cache Chỉnh)
                StudioDisclosure("Vị trí & tọa độ") { xyzTuningSlidersCard }
                
                // 5. Bone & Scale Config Card
                StudioDisclosure("Khung & tỷ lệ") { boneAndScaleConfigCard }
                
                // 6. Big Weapon (Súng To) Card
                StudioDisclosure("Cấu hình vật phẩm") { bigWeaponConfigCard }
                
                // 7. Protection & Integrity Options Card
                StudioDisclosure("Tùy chọn bản dựng") { protectionOptionsCard }
                
                // 8. Source File Selection Card
                sourceFileCard
                
                // 9. Action Buttons (Make via API, 1-Click Install, Share Sheet)
                actionButtonsCard
                
                // 10. Applied Changes Log View (When built)
                if !appliedChanges.isEmpty {
                    changesLogCard
                }
                
                Spacer().frame(height: 30)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .frame(maxWidth: 760).frame(maxWidth: .infinity)
        }
        .background(theme.backgroundColor.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { if isBuilding { StudioBusyBar(text: "Đang tạo bản dựng Avatar…") } }
        .navigationTitle(loc.isVN ? "Tạo Avatar" : "Make Avatar")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.data, .item],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Header Banner
    private var headerBannerView: some View {
        StudioHero(eyebrow: "STUDIO / AVATAR", title: "Thiết kế nhân vật.", subtitle: "Bắt đầu từ một mẫu, xem trước và tạo bản dựng của bạn.", icon: "person.crop.square")
    }


    // MARK: - Server Status Pill
    private var serverStatusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(api.isOnline ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text(api.isOnline ? "VPS CONTROLLER ONLINE" : "OFFLINE")
                .font(.system(size: 11, weight: .heavy))
                .foregroundColor(api.isOnline ? .green : .red)
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 12))
                    .foregroundColor(api.isVIP2 ? .purple : .gray)
                Text(api.isVIP2 ? "Đã Kích Hoạt VIP 2" : "Yêu Cầu VIP 2")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(api.isVIP2 ? .purple : .gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(theme.primaryText.opacity(0.04))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.primaryText.opacity(0.08), lineWidth: 1))
    }
    
    // MARK: - 1. Game Version Selector (Shader-Style Interactive Tap Feedback)
    private var gameVersionSelectorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "gamecontroller.fill")
                    .foregroundColor(theme.accentColor)
                    .font(.system(size: 13))
                Text("BẢN GAME MỤC TIÊU")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.primaryText)
                Spacer()
            }
            
            HStack(spacing: 12) {
                gameVersionCardButton(
                    version: .fft,
                    title: "Free Fire Thường",
                    subtitle: "com.dts.freefireth • Bản gốc",
                    accentColor: .cyan
                )
                
                gameVersionCardButton(
                    version: .ffm,
                    title: "Free Fire MAX",
                    subtitle: "com.dts.freefiremax • Đồ họa cao",
                    accentColor: .purple
                )
            }
        }
        .padding(14)
        .background(theme.cardBackground)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(theme.cardBorder, lineWidth: 1))
    }
    
    private func gameVersionCardButton(
        version: GameVersion,
        title: String,
        subtitle: String,
        accentColor: Color
    ) -> some View {
        let isSelected = (selectedGame == version)
        return Button(action: {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                selectedGame = version
            }
        }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(theme.primaryText)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(accentColor)
                            .font(.system(size: 17))
                    } else {
                        Circle()
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
                            .frame(width: 17, height: 17)
                    }
                }
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryText)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(isSelected ? accentColor.opacity(0.16) : theme.primaryText.opacity(0.04))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? accentColor : theme.primaryText.opacity(0.08), lineWidth: isSelected ? 1.8 : 1)
            )
            .shadow(color: isSelected ? accentColor.opacity(0.3) : Color.clear, radius: 6)
        }
    }
    
    // MARK: - 2. Preset Selector (Shader-Style Dynamic Selection Feedback)
    private var presetSelectorCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(.yellow)
                    .font(.system(size: 13))
                Text("1. CHỌN MẪU AVATAR (PRESETS)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.accentColor)
                Spacer()
                Text("1-Chạm kích hoạt")
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryText)
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(presets) { preset in
                    presetCardButton(preset: preset)
                }
            }
        }
        .padding(14)
        .background(theme.cardBackground)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(theme.cardBorder, lineWidth: 1))
    }
    
    private func presetCardButton(preset: AvatarPresetItem) -> some View {
        let isSelected = (selectedPresetId == preset.id)
        return Button(action: {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                selectPreset(preset)
            }
        }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(preset.color.opacity(isSelected ? 0.35 : 0.15))
                            .frame(width: 28, height: 28)
                        Image(systemName: preset.icon)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(preset.color)
                    }
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 15))
                            .foregroundColor(preset.color)
                            .shadow(color: preset.color.opacity(0.6), radius: 4)
                    } else {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1.2)
                            .frame(width: 14, height: 14)
                    }
                }
                
                Text(preset.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(theme.primaryText)
                    .lineLimit(1)
                
                Text(preset.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryText)
                    .lineLimit(1)
            }
            .padding(11)
            .background(
                isSelected ?
                preset.color.opacity(0.20) :
                Color.white.opacity(0.035)
            )
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? preset.color : theme.primaryText.opacity(0.08), lineWidth: isSelected ? 2.0 : 1)
            )
            .shadow(color: isSelected ? preset.color.opacity(0.4) : Color.clear, radius: 8)
        }
    }
    
    // MARK: - 3. Live Avatar Simulation & Hitbox Check Canvas (Như Cache Mô Phỏng)
    private var liveAvatarHitboxCanvasCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "viewfinder")
                    .foregroundColor(activePreset.color)
                    .font(.system(size: 14))
                Text("2. MÔ PHỎNG AVATAR & HITBOX CHECK")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.primaryText)
                Spacer()
                
                Text("Visual Mannequin")
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryText)
            }
            
            // Interactive Live Canvas (Vector Schematics from dpi)
            AvatarPreviewCanvas(
                targetBone: targetBone,
                scaleVal: scaleVal,
                posX: posX,
                posY: posY,
                posZ: posZ,
                isAntena: activePreset.isAntena,
                modBigGun: modBigGun,
                gunScale: gunScale,
                accentColor: activePreset.color,
                onSelectJoint: { jointKey in
                    if let match = presets.first(where: { $0.id == jointKey }) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                            selectPreset(match)
                        }
                    } else if jointKey == "aim_arms_hs" || jointKey == "aim_legs_hs" {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                            selectedPresetId = "custom"
                            targetBone = (jointKey == "aim_arms_hs") ? "bone_Arms" : "bone_Legs"
                            scaleVal = 2.50
                            posX = (jointKey == "aim_arms_hs") ? -0.07 : -0.10
                        }
                    }
                }
            )
        }
        .padding(14)
        .background(theme.cardBackground)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(theme.cardBorder, lineWidth: 1))
    }
    
    // MARK: - 4. XYZ Coordinate Tuning Sliders (Chuẩn dpi: X Cao/Thấp, Y Trước/Sau, Z Trái/Phải)
    private var xyzTuningSlidersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(theme.accentColor)
                    .font(.system(size: 14))
                Text("3. ĐIỀU CHỈNH TỌA ĐỘ VỊ TRÍ HITBOX (X, Y, Z OFFSET)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.accentColor)
                Spacer()
                
                Button(action: {
                    withAnimation {
                        selectPreset(activePreset)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12))
                        Text("Reset Về Mẫu")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.primaryText.opacity(0.08))
                    .foregroundColor(.gray)
                    .cornerRadius(6)
                }
            }
            
            Text("Theo chuẩn Unity AssetIndexer: Trục X điều chỉnh độ cao dọc thân (Đỉnh đầu / Cổ / Ngực / Hông).")
                .font(.system(size: 12))
                .foregroundColor(theme.secondaryText)
            
            // XYZ Slider Rows (Exact dpi boundaries)
            VStack(spacing: 12) {
                // Trục X: Cao / Thấp
                xyzSliderRow(
                    title: "Trục X (Độ Cao Tâm Ngắm: Đỉnh Đầu / Cổ / Ngực / Hông)",
                    value: $posX,
                    range: -0.50...0.30,
                    step: 0.005,
                    color: .cyan
                )
                
                // Trục Y: Trước / Sau
                xyzSliderRow(
                    title: "Trục Y (Độ lệch Trước / Sau)",
                    value: $posY,
                    range: -0.15...0.15,
                    step: 0.002,
                    color: .green
                )
                
                // Trục Z: Trái / Phải
                xyzSliderRow(
                    title: "Trục Z (Độ lệch Trái / Phải)",
                    value: $posZ,
                    range: -0.15...0.15,
                    step: 0.002,
                    color: .yellow
                )
            }
            
            Divider().background(theme.primaryText.opacity(0.08))
            
            // 1-Tap Quick Position Markers (Matching dpi index.html lines 575-580)
            VStack(alignment: .leading, spacing: 6) {
                Text("Vị trí mốc chuẩn (Nhấn để ghim nhanh độ cao Trục X):")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
                
                HStack(spacing: 6) {
                    quickPositionButton(title: "Đầu (-0.157)", targetX: -0.1566203)
                    quickPositionButton(title: "Hạ Cổ (-0.087)", targetX: -0.086620286)
                    quickPositionButton(title: "Ngực (0.000)", targetX: 0.0)
                    quickPositionButton(title: "Hông (+0.200)", targetX: 0.20)
                    quickPositionButton(title: "Anten (-0.375)", targetX: -0.3749083)
                }
            }
        }
        .padding(14)
        .background(theme.cardBackground)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(theme.cardBorder, lineWidth: 1))
    }
    
    // Helper Slider Row for XYZ
    private func xyzSliderRow(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(theme.primaryText)
                Spacer()
                Text(String(format: "%+.4f", value.wrappedValue))
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(color)
            }
            
            HStack(spacing: 10) {
                Button(action: {
                    value.wrappedValue = max(range.lowerBound, value.wrappedValue - step * 5)
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
                
                Slider(value: value, in: range, step: step)
                    .accentColor(color)
                
                Button(action: {
                    value.wrappedValue = min(range.upperBound, value.wrappedValue + step * 5)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.025))
        .cornerRadius(10)
    }
    
    private func quickPositionButton(title: String, targetX: Double) -> some View {
        let isMatch = abs(posX - targetX) < 0.01
        return Button(action: {
            withAnimation {
                posX = targetX
            }
        }) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 5)
                .background(isMatch ? theme.accentColor : theme.primaryText.opacity(0.06))
                .foregroundColor(isMatch ? theme.onAccent : theme.primaryText)
                .cornerRadius(6)
        }
    }
    
    // MARK: - 5. Bone & Scale Config Card
    private var boneAndScaleConfigCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("4. CẤU HÌNH HITBOX & BONE")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(theme.accentColor)
            
            // Bone Name & Parent Hash
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tên Bone Đích")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    TextField("bone_Head", text: $targetBone)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.primaryText)
                        .padding(8)
                        .background(theme.primaryText.opacity(0.06))
                        .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Parent Bone Hash")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    Text("\(parentHash)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.accentColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(theme.primaryText.opacity(0.06))
                        .cornerRadius(8)
                }
            }
            
            // Hitbox Scale Slider
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Hệ Số Phóng To Hitbox (Scale)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(theme.primaryText)
                    Spacer()
                    Text(String(format: "%.2fx", scaleVal))
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(theme.accentColor)
                }
                
                Slider(value: $scaleVal, in: 0.5...5.0, step: 0.05)
                    .accentColor(.cyan)
                
                HStack(spacing: 8) {
                    ForEach([1.20, 1.55, 2.00, 3.00, 4.50], id: \.self) { quickVal in
                        Button(action: { scaleVal = quickVal }) {
                            Text(String(format: "%.2fx", quickVal))
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(abs(scaleVal - quickVal) < 0.01 ? theme.accentColor : theme.primaryText.opacity(0.08))
                                .foregroundColor(abs(scaleVal - quickVal) < 0.01 ? theme.onAccent : theme.primaryText)
                                .cornerRadius(6)
                        }
                    }
                }
            }
            
            // Character selection
            HStack(spacing: 16) {
                Toggle(isOn: $modMale) {
                    Text("Nam (BaseBoneMale)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.primaryText)
                }
                .toggleStyle(SwitchToggleStyle(tint: .cyan))
                
                Toggle(isOn: $modFemale) {
                    Text("Nữ (BaseBoneFemale)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.primaryText)
                }
                .toggleStyle(SwitchToggleStyle(tint: .cyan))
            }
        }
        .padding(14)
        .background(theme.cardBackground)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(theme.cardBorder, lineWidth: 1))
    }
    
    // MARK: - 6. Big Weapon (Súng To) Card
    private var bigWeaponConfigCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("5. CHỈNH SÚNG TO (BIG WEAPON)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.orange)
                Spacer()
                Toggle("", isOn: $modBigGun)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .orange))
            }
            
            if modBigGun {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Kích thước súng cầm tay & sau lưng")
                            .font(.system(size: 11))
                            .foregroundColor(theme.secondaryText)
                        Spacer()
                        Text(String(format: "%.1fx", gunScale))
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                    
                    Slider(value: $gunScale, in: 1.0...8.0, step: 0.5)
                        .accentColor(.orange)
                }
            } else {
                Text("Bật để phóng to vũ khí cầm tay và đeo lưng, tạo hiệu ứng thị giác hoành tráng.")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(14)
        .background(theme.cardBackground)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(modBigGun ? Color.orange.opacity(0.4) : theme.cardBorder, lineWidth: 1))
    }
    
    // MARK: - 7. Protection & Integrity Options Card
    private var protectionOptionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("6. CƠ CHẾ CHỐNG BAN & BYPASS INTEGRITY")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                Toggle(isOn: $matchSize) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Chuẩn Hóa Header & Zero-Padding 46,096 Bytes")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(theme.primaryText)
                        Text("Auto-unobfuscate 2018.4.12f1 -> 2022.3.47f1 khi mod, re-spoof về 2018.4.12f1 và đệm byte 0x00 chuẩn 46,096 bytes")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .green))
                
                Divider().background(theme.primaryText.opacity(0.08))
                
                Toggle(isOn: $patchMono) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Vá MonoScript Assembly (.dll)")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(theme.primaryText)
                        Text("Đồng bộ Assembly-CSharp.dll tương thích môi trường runtime iOS")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .green))
            }
        }
        .padding(14)
        .background(theme.cardBackground)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(theme.cardBorder, lineWidth: 1))
    }
    
    // MARK: - 8. Source File Selection Card
    private var sourceFileCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("7. FILE NGUỒN ASSETINDEXER")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(theme.accentColor)
            
            HStack(spacing: 10) {
                Image(systemName: "doc.zipper")
                    .font(.system(size: 20))
                    .foregroundColor(theme.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(customFileName ?? "assetindexer.U6Zffc4YIR3DslNj3cXvYGAqz58~3D")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.primaryText)
                        .lineLimit(1)
                    
                    Text(customFileData != nil ? "File tùy chỉnh từ máy (\(customFileData!.count) bytes)" : "File gốc mặc định trên máy chủ VPS (46,096 bytes)")
                        .font(.system(size: 12))
                        .foregroundColor(customFileData != nil ? .green : .gray)
                }
                
                Spacer()
                
                Button(action: {
                    if customFileData != nil {
                        customFileName = nil
                        customFileData = nil
                    } else {
                        showFileImporter = true
                    }
                }) {
                    Text(customFileData != nil ? "Dùng Gốc" : "Chọn Tệp")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(customFileData != nil ? Color.gray.opacity(0.3) : theme.accentColor.opacity(0.2))
                        .foregroundColor(customFileData != nil ? .white : .cyan)
                        .cornerRadius(8)
                }
            }
        }
        .padding(14)
        .background(theme.cardBackground)
        .cornerRadius(24)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(theme.cardBorder, lineWidth: 1))
    }
    
    // MARK: - 9. Action Buttons Card
    private var actionButtonsCard: some View {
        StudioPanel("Bản dựng Avatar", icon: "arrow.down.doc") {
            Button(action: buildAvatarViaAPI) {
                Label(isBuilding ? "Đang tạo bản dựng…" : "Tạo Avatar", systemImage: "sparkles")
            }.buttonStyle(StudioActionStyle()).disabled(isBuilding)
            if builtData != nil {
                Label("Bản dựng đã sẵn sàng", systemImage: "checkmark.circle.fill").font(.subheadline).foregroundColor(.green)
                Button(action: shareBuiltFile) { Label("Lưu hoặc chia sẻ", systemImage: "square.and.arrow.up") }
                    .buttonStyle(StudioActionStyle(secondary: true)).disabled(isBuilding)
                Button(action: directInstallToGame) { Label("Cài vào game", systemImage: "square.and.arrow.down") }
                    .buttonStyle(StudioActionStyle(secondary: true)).disabled(isBuilding)
            }
        }
    }

    // MARK: - 10. Changes Log Card (Hiển thị kiểu đã chọn, chỉnh gì & Done file)
    private var changesLogCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                Text("THÔNG TIN CẤU HÌNH & KẾT QUẢ MAKE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.green)
                Spacer()
                Text("Done File")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.18))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            }
            
            Divider().background(theme.primaryText.opacity(0.08))
            
            ForEach(appliedChanges, id: \.self) { change in
                let isDone = change.contains("Done file")
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: isDone ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                        .foregroundColor(isDone ? .green : .cyan)
                        .font(.system(size: 11))
                    Text(change)
                        .font(.system(size: 12, weight: isDone ? .bold : .medium))
                        .foregroundColor(isDone ? .green : theme.primaryText)
                }
            }
        }
        .padding(12)
        .background(theme.cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.25), lineWidth: 1))
    }
    
    // MARK: - Helper Methods
    private func selectPreset(_ preset: AvatarPresetItem) {
        selectedPresetId = preset.id
        targetBone = preset.bone
        parentHash = preset.hash
        scaleVal = preset.defaultScale
        posX = preset.posX
        posY = preset.posY
        posZ = preset.posZ
        rotX = preset.rotX
        rotY = preset.rotY
        rotZ = preset.rotZ
        rotW = preset.rotW
        if preset.isAntena {
            modBigGun = false
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                if let data = try? Data(contentsOf: url) {
                    customFileData = data
                    customFileName = url.lastPathComponent
                }
            }
        case .failure(let err):
            alertTitle = "Lỗi chọn file"
            alertMessage = err.localizedDescription
            showAlert = true
        }
    }
    
    private func buildAvatarViaAPI() {
        guard api.isVIP2 else {
            alertTitle = "Yêu Cầu VIP 2"
            alertMessage = "Tính năng Make Avatar (AssetIndexer) chỉ dành riêng cho tài khoản VIP 2! Vui lòng liên hệ Admin MeoNxt để nâng cấp gói VIP 2."
            showAlert = true
            return
        }
        
        isBuilding = true
        builtData = nil
        appliedChanges = []
        
        let customB64 = customFileData?.base64EncodedString()
        
        api.buildAvatarMod(
            presetId: selectedPresetId,
            targetBone: targetBone,
            parentHash: parentHash,
            scale: scaleVal,
            modMale: modMale,
            modFemale: modFemale,
            modBigGun: modBigGun,
            gunScale: gunScale,
            matchSize: matchSize,
            patchMono: patchMono,
            posX: posX,
            posY: posY,
            posZ: posZ,
            rotX: rotX,
            rotY: rotY,
            rotZ: rotZ,
            rotW: rotW,
            gameVersion: selectedGame.rawValue,
            customFileBase64: customB64
        ) { result in
            DispatchQueue.main.async {
                self.isBuilding = false
                switch result {
                case .success(let payload):
                    self.builtData = payload.data
                    self.builtFilename = payload.filename
                    self.appliedChanges = payload.changes
                    
                    self.alertTitle = "Thành Công! 🎉"
                    self.alertMessage = "Đã tạo thành công file \(payload.filename) qua API VPS! Bạn có thể cài trực tiếp vào game hoặc lưu vào tệp."
                    self.showAlert = true
                    
                case .failure(let err):
                    self.alertTitle = "Thất Bại"
                    self.alertMessage = err.localizedDescription
                    self.showAlert = true
                }
            }
        }
    }
    
    private func directInstallToGame() {
        guard let data = builtData else { return }
        let result = GameInjector.shared.directInjectToGame(
            version: selectedGame,
            filename: builtFilename,
            data: data
        )
        alertTitle = result.success ? "Cài Đặt Thành Công!" : "Thông Báo"
        alertMessage = result.message
        showAlert = true
    }
    
    private func shareBuiltFile() {
        guard let data = builtData else { return }
        if let tempURL = GameInjector.shared.saveTempFile(data: data, filename: builtFilename) {
            GameInjector.shared.presentShareSheet(fileURL: tempURL)
        }
    }
}
