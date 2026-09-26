import SwiftUI

public struct AuthorCreditsView: View {
    @ObservedObject var theme = ThemeManager.shared
    @ObservedObject var loc = LocalizationManager.shared
    @State private var copied: Bool = false
    
    private let telegramURL = "https://t.me/truongdeptrai7"
    private let telegramUsername = "@truongdeptrai7"
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                StudioHero(eyebrow: "STUDIO / CONNECT", title: "Cùng xây dựng Studio.", subtitle: "Thông tin tác giả và kênh hỗ trợ của ứng dụng.", icon: "bubble.left.and.bubble.right")
                // Header Scenic Banner
                VStack(spacing: 22) {
                    if let uiImg = UIImage(named: "admin_avatar") ?? (Bundle.main.path(forResource: "admin_avatar", ofType: "png").flatMap { UIImage(contentsOfFile: $0) }) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 96, height: 96)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [theme.accentColor, Color.purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2.5
                                    )
                            )
                            .shadow(color: theme.accentColor.opacity(0.5), radius: 14, y: 6)
                            .padding(.top, 16)
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(theme.accentColor)
                            .padding(.top, 16)
                    }
                    
                    VStack(spacing: 6) {
                        Text(loc.isVN ? "SÁNG TÁC & PHÁT TRIỂN" : "AUTHOR & CREATOR")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(theme.primaryText)
                        
                        Text(loc.isVN ? "Hệ Thống Mod Free Fire Độc Quyền" : "Exclusive Free Fire Modding System")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                    }
                }
                
                // Creator Profile Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        if let uiImg = UIImage(named: "admin_avatar") ?? (Bundle.main.path(forResource: "admin_avatar", ofType: "png").flatMap { UIImage(contentsOfFile: $0) }) {
                            Image(uiImage: uiImg)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 46, height: 46)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(theme.accentColor.opacity(0.7), lineWidth: 1.5))
                        } else {
                            Circle()
                                .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 46, height: 46)
                                .overlay(
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(.white)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CheatiOS Vip")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(theme.primaryText)
                            Text(telegramUsername)
                                .font(.caption)
                                .foregroundColor(theme.accentColor)
                        }
                        
                        Spacer()
                        
                        Text("AUTHOR")
                            .font(.system(size: 12, weight: .black))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(theme.accentColor.opacity(0.15))
                            .foregroundColor(theme.accentColor)
                            .clipShape(Capsule())
                    }
                    
                    Divider().background(theme.cardBorder)
                    
                    Text(loc.isVN ?
                         "Dự án Build File được sáng tác và nghiên cứu cấu trúc nhị phân độc quyền dành cho Free Fire & Free Fire MAX trên hệ điều hành iOS." :
                         "Build File project is authored and researched exclusively for Free Fire & Free Fire MAX on iOS operating systems.")
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                        .lineSpacing(4)
                    
                    // Clickable Telegram Button
                    Button(action: openTelegram) {
                        HStack(spacing: 10) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text(loc.isVN ? "Liên Hệ Telegram: @truongdeptrai7" : "Contact Telegram: @truongdeptrai7")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.15, green: 0.55, blue: 0.95), Color(red: 0.05, green: 0.75, blue: 0.95)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: theme.accentColor.opacity(0.35), radius: 8, y: 4)
                    }
                    
                    // Copy username button
                    Button(action: {
                        UIPasteboard.general.string = "https://t.me/truongdeptrai7"
                        copied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                    }) {
                        HStack {
                            Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                                .font(.caption)
                            Text(copied ? (loc.isVN ? "Đã sao chép liên kết!" : "Link Copied!") : (loc.isVN ? "Sao Chép Link Telegram" : "Copy Telegram Link"))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(copied ? .green : .gray)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(18)
                .background(theme.cardBackground)
                .cornerRadius(18)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(theme.cardBorder, lineWidth: 1))
                .padding(.horizontal)
                
                // Specifications & Security Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text(loc.isVN ? "THÔNG TIN PHIÊN BẢN" : "VERSION INFORMATION")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text(loc.isVN ? "Phiên bản:" : "Version:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("Build File v2.0.15 (Official)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryText)
                    }
                    
                    HStack {
                        Text(loc.isVN ? "Tương thích:" : "Compatibility:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("iOS 15.0 - iOS 18+")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryText)
                    }
                    
                    HStack {
                        Text(loc.isVN ? "Bản quyền:" : "Copyright:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("© 2026 CheatiOS Vip")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(theme.accentColor)
                    }
                }
                .padding(16)
                .background(theme.cardBackground)
                .cornerRadius(24)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(theme.cardBorder, lineWidth: 1))
                .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
        .navigationTitle(loc.isVN ? "Sáng Tác" : "Credits")
    }
    
    private func openTelegram() {
        if let url = URL(string: telegramURL) {
            UIApplication.shared.open(url)
        }
    }
}
