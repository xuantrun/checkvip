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
        case .dark: return Color(red: 0.035, green: 0.055, blue: 0.075)
        case .light: return Color(red: 0.96, green: 0.97, blue: 0.98)
        case .monochrome: return Color.black
        }
    }
    
    // Card background
    public var cardBackground: Color {
        switch currentTheme {
        case .dark: return Color(red: 0.075, green: 0.10, blue: 0.12)
        case .light: return Color.white
        case .monochrome: return Color(white: 0.065)
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
        case .dark: return Color(red: 0.49, green: 0.91, blue: 0.76)
        case .light: return Color(red: 0.04, green: 0.40, blue: 0.32)
        case .monochrome: return Color.white
        }
    }
    
    // Cyberpunk & Neon Design Tokens
    public var neonCyan: Color {
        return Color(red: 0.49, green: 0.91, blue: 0.76)
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
    
    public var onAccent: Color { currentTheme == .light ? .white : .black }
    public var cardGradient: LinearGradient {
        LinearGradient(colors: [cardBackground, accentColor.opacity(0.09)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}


// Shared Studio surfaces. Kept in this compilation unit for iOS 15 targets.
struct StudioHero: View {
    @ObservedObject private var theme = ThemeManager.shared
    let eyebrow: String
    let title: String
    let subtitle: String
    let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(eyebrow.uppercased()).font(.caption.weight(.bold)).tracking(2)
                Spacer()
                Image(systemName: icon).font(.title2)
            }.foregroundColor(theme.accentColor)
            Text(title).font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundColor(theme.primaryText).fixedSize(horizontal: false, vertical: true)
            Text(subtitle).font(.subheadline).foregroundColor(theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(24)
        .background(theme.cardGradient).clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(theme.cardBorder, lineWidth: 1))
    }
}

struct StudioPanel<Content: View>: View {
    @ObservedObject private var theme = ThemeManager.shared
    let title: String
    let icon: String
    let content: Content
    init(_ title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title; self.icon = icon; self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label(title, systemImage: icon).font(.headline).foregroundColor(theme.primaryText)
            content
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.cardBackground).clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(theme.cardBorder, lineWidth: 1))
    }
}

struct StudioDisclosure<Content: View>: View {
    @ObservedObject private var theme = ThemeManager.shared
    @State private var expanded = false
    let title: String
    let content: Content
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title; self.content = content()
    }
    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            VStack(spacing: 18) { content }.padding(.top, 16)
        } label: {
            Label(title, systemImage: "slider.horizontal.3")
                .font(.headline).foregroundColor(theme.primaryText)
        }.padding(20).background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(theme.cardBorder, lineWidth: 1))
    }
}

struct StudioEmptyState: View {
    @ObservedObject private var theme = ThemeManager.shared
    let title: String
    let message: String
    let icon: String
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon).font(.system(size: 38)).foregroundColor(theme.accentColor)
                .frame(width: 84, height: 84).background(theme.accentColor.opacity(0.09))
                .clipShape(RoundedRectangle(cornerRadius: 28))
            Text(title).font(.title3.bold()).foregroundColor(theme.primaryText)
            Text(message).font(.subheadline).foregroundColor(theme.secondaryText)
        }.multilineTextAlignment(.center).padding(28).frame(maxWidth: .infinity)
    }
}

struct StudioActionStyle: ButtonStyle {
    @ObservedObject private var theme = ThemeManager.shared
    @Environment(\.isEnabled) private var enabled
    var secondary = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity, minHeight: 52)
            .foregroundColor(secondary ? theme.primaryText : theme.onAccent)
            .background(secondary ? theme.primaryText.opacity(0.055) : theme.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .opacity(enabled ? (configuration.isPressed ? 0.75 : 1) : 0.4)
    }
}

struct StudioBusyBar: View {
    @ObservedObject private var theme = ThemeManager.shared
    let text: String
    var body: some View {
        HStack(spacing: 12) {
            ProgressView().tint(theme.accentColor)
            Text(text).font(.subheadline.weight(.semibold)).foregroundColor(theme.primaryText)
            Spacer()
        }.padding(18).background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18)).padding(.horizontal, 20)
            .padding(.bottom, 8).accessibilityElement(children: .combine)
    }
}
