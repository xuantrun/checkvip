import Foundation

public struct HitboxPreset: Identifiable, Codable {
    public let id: String
    public let title: String
    public let icon: String
    public let desc: String
    public let imageName: String?
    
    public init(id: String, title: String, icon: String, desc: String, imageName: String? = nil) {
        self.id = id
        self.title = title
        self.icon = icon
        self.desc = desc
        self.imageName = imageName
    }
}

public struct HitboxConfig {
    public static let defaultPresets: [HitboxPreset] = [
        HitboxPreset(
            id: "nhe_tam",
            title: "Mod Nhẹ Tâm",
            icon: "⚡",
            desc: "Radius 0.099m, Center X +0.055m nhẹ tâm ghim đầu cực nhạy!",
            imageName: "preset_headshot"
        ),
        HitboxPreset(
            id: "cheast",
            title: "Ghim Headshot (cache cheast)",
            icon: "🎯",
            desc: "Đầu to +68%, kéo nhẹ cổ/ngực",
            imageName: "preset_headshot"
        ),
        HitboxPreset(
            id: "body",
            title: "Bắn Thân = Headshot (cache body)",
            icon: "💥",
            desc: "Kéo tâm đầu tụt xuống giữa bụng/thân",
            imageName: "preset_body"
        ),
        HitboxPreset(
            id: "sniper_hitbox",
            title: "Sniper Siêu Trúng Đích (AWM / M82B)",
            icon: "🔭",
            desc: "Phóng to riêng Hitbox Sniper 1.2m: Bắn ngắm lệch vẫn tự dính đạn!",
            imageName: "preset_headshot"
        ),
        HitboxPreset(
            id: "magic",
            title: "Magic Bullet (magic cache)",
            icon: "🔮",
            desc: "Hitbox thân (bone_Spine) phình to bao quanh người!",
            imageName: "preset_magic"
        ),
        HitboxPreset(
            id: "super_magic",
            title: "Super Magic 360° (Full Thân-Ngực)",
            icon: "🌪️",
            desc: "Phình to toàn bộ Thân + Ngực + Hông 1.07m bao trọn 360°!",
            imageName: "preset_magic"
        ),
        HitboxPreset(
            id: "combo_cheast_magic",
            title: "Combo: Headshot + Magic",
            icon: "👑",
            desc: "Vừa ghim đầu + Vừa hitbox thân khổng lồ!",
            imageName: "preset_magic"
        ),
        HitboxPreset(
            id: "goc",
            title: "Khôi Phục Gốc (Chuẩn Game)",
            icon: "🔄",
            desc: "Đưa tất cả về thông số nguyên bản 100%",
            imageName: "hitbox_mannequin"
        )
    ]
}
