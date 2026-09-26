import Foundation
import SwiftUI

public enum AppLanguage: String, CaseIterable, Identifiable {
    case vietnamese = "vi"
    case english = "en"
    
    public var id: String { self.rawValue }
    
    public var displayName: String {
        switch self {
        case .vietnamese: return "Tiếng Việt"
        case .english: return "English"
        }
    }
}

public final class LocalizationManager: ObservableObject {
    public static let shared = LocalizationManager()
    
    @Published public var currentLanguage: AppLanguage = .vietnamese {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
        }
    }
    
    public var isVN: Bool {
        return currentLanguage == .vietnamese
    }
    
    private init() {
        if let saved = UserDefaults.standard.string(forKey: "app_language"),
           let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        }
    }
    
    public func t(_ key: String) -> String {
        let isVN = currentLanguage == .vietnamese
        switch key {
        // Tabs
        case "tab_gun": return "Shader"
        case "tab_hitbox": return "Cache_res"
        case "tab_avatar": return isVN ? "Make Avt" : "Avatar"
        case "tab_guide": return isVN ? "Hướng Dẫn" : "Guide"
        case "tab_settings": return isVN ? "Cài Đặt" : "Settings"
        case "tab_account": return isVN ? "Tài Khoản" : "Account"
            
        // Common
        case "app_title": return "BUILD FILE"
        case "app_subtitle": return isVN ? "Hệ Thống Tùy Biến Free Fire Chuyên Nghiệp" : "Professional Free Fire Mod Studio"
        case "status_online": return isVN ? "Đã Kết Nối VPS" : "VPS Connected"
        case "status_offline": return isVN ? "Mất Kết Nối VPS" : "VPS Offline"
        case "hwid_label": return isVN ? "Mã Thiết Bị (HWID)" : "Device HWID"
        case "api_key_label": return "API Key"
        case "auth_required": return isVN ? "Yêu cầu đăng nhập và API Key hợp lệ" : "Authentication & valid API Key required"
        case "auth_blocked_hwid": return isVN ? "Thiết bị này (HWID) đã bị quản trị viên chặn!" : "This device (HWID) has been blocked by admin!"
        case "login": return isVN ? "Đăng Nhập" : "Sign In"
        case "register": return isVN ? "Đăng Ký" : "Sign Up"
        case "logout": return isVN ? "Đăng Xuất" : "Sign Out"
        case "username": return isVN ? "Tên tài khoản" : "Username"
        case "password": return isVN ? "Mật khẩu" : "Password"
            
        // Themes
        case "theme_dark": return isVN ? "Giao Diện Tối" : "Dark Mode"
        case "theme_light": return isVN ? "Giao Diện Sáng" : "Light Mode"
        case "theme_mono": return isVN ? "Trắng Đen (OLED)" : "Monochrome OLED"
        case "language": return isVN ? "Ngôn Ngữ" : "Language"
            
        // Gun Shaders
        case "gun_title": return isVN ? "Shader" : "Shader"
        case "gun_step1": return isVN ? "Chọn Phiên Bản Game" : "Select Game Version"
        case "gun_step2": return isVN ? "Tùy Chọn Màu Sắc & Nền" : "Colors & Backdrop Configuration"
        case "gun_color1": return isVN ? "Màu Thân Súng" : "Weapon Base Color"
        case "gun_color2": return isVN ? "Mảng Nền Poster" : "Backdrop Poster Color"
        case "gun_width": return isVN ? "Độ Dày Mảng Nền" : "Outline & Backdrop Thickness"
        case "gun_export": return isVN ? "XUẤT FILE SHADER MOD" : "GENERATE SHADER MOD"
            
        // Hitbox
        case "hitbox_title": return isVN ? "Cache" : "Cache"
        case "hitbox_upload_step": return isVN ? "Tải Lên Tệp Cache Của Bạn" : "Upload Your Cache File"
        case "hitbox_choose_file": return isVN ? "Chọn tệp cache_res từ máy..." : "Choose cache_res from device..."
        case "hitbox_presets": return isVN ? "Công Thức 1-Chạm" : "1-Tap Presets"
        case "hitbox_custom": return isVN ? "Tinh Chỉnh Chi Tiết" : "Manual Coordinates"
        case "hitbox_export": return isVN ? "XUẤT & LƯU TỆP CACHE" : "EXPORT & SAVE CACHE"
            
        default: return key
        }
    }
}
