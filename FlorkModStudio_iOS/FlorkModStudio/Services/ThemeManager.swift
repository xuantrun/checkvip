import Foundation
import SwiftUI

public enum AppThemeMode: String, CaseIterable, Identifiable {
    case dark = "dark"
    case light = "light"
    case monochrome = "mono"
    
    public var id: String { self.rawValue }
    
    public var title: String {
        switch self {
        case .dark: return "Tối (Dark)"
        case .light: return "Sáng (Light)"
        case .monochrome: return "Trắng Đen (OLED)"
        }
    }
}

public final class ThemeManager: ObservableObject {
    public static let shared = ThemeManager()
    
    @Published public var currentTheme: AppThemeMode = .dark {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "app_theme_mode")
        }
    }
    
    private init() {
        if let saved = UserDefaults.standard.string(forKey: "app_theme_mode"),
           let t = AppThemeMode(rawValue: saved) {
            self.currentTheme = t
        }
    }
    
    public var colorScheme: ColorScheme {
        switch currentTheme {
        case .light: return .light
        case .dark, .monochrome: return .dark
        }
    }
    
    // Background color
    public var backgroundColor: Color {
        switch currentTheme {
        case .dark: return Color(red: 0.08, green: 0.10, blue: 0.16)
        case .light: return Color(red: 0.96, green: 0.97, blue: 0.98)
        case .monochrome: return Color(red: 0.06, green: 0.06, blue: 0.08)
        }
    }
    
    // Card background
    public var cardBackground: Color {
        switch currentTheme {
        case .dark: return Color(red: 0.12, green: 0.15, blue: 0.24)
        case .light: return Color.white
        case .monochrome: return Color(red: 0.12, green: 0.12, blue: 0.14)
        }
    }
    
    // Card border
    public var cardBorder: Color {
        switch currentTheme {
        case .dark: return Color.white.opacity(0.12)
        case .light: return Color.black.opacity(0.08)
        case .monochrome: return Color.white.opacity(0.2)
        }
    }
    
    // Primary text
    public var primaryText: Color {
        switch currentTheme {
        case .dark, .monochrome: return Color.white
        case .light: return Color(red: 0.05, green: 0.08, blue: 0.15)
        }
    }
    
    // Secondary text
    public var secondaryText: Color {
        switch currentTheme {
        case .dark: return Color(red: 0.58, green: 0.64, blue: 0.72)
        case .light: return Color(red: 0.40, green: 0.45, blue: 0.55)
        case .monochrome: return Color.gray
        }
    }
    
    // Accent / Brand color
    public var accentColor: Color {
        switch currentTheme {
        case .dark: return Color(red: 0.0, green: 0.95, blue: 1.0)
        case .light: return Color.blue
        case .monochrome: return Color.white
        }
    }
    
    // Cyberpunk & Neon Design Tokens
    public var neonCyan: Color {
        return Color(red: 0.0, green: 0.95, blue: 1.0)
    }
    
    public var neonPurple: Color {
        return Color(red: 0.72, green: 0.35, blue: 1.0)
    }
    
    public var neonGold: Color {
        return Color(red: 1.0, green: 0.82, blue: 0.2)
    }
    
    public var cyberGradient: LinearGradient {
        LinearGradient(
            colors: [Color(red: 0.0, green: 0.88, blue: 1.0), Color(red: 0.65, green: 0.25, blue: 1.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    public var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.12, green: 0.15, blue: 0.24),
                Color(red: 0.09, green: 0.11, blue: 0.18)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
