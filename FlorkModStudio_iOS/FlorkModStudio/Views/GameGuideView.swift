import SwiftUI

public struct GameGuideView: View {
    @ObservedObject var loc = LocalizationManager.shared
    @ObservedObject var theme = ThemeManager.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                
                // Header Banner
                VStack(alignment: .leading, spacing: 6) {
                    Text("HƯỚNG DẪN CÀI ĐẶT BUILD FILE")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.cyan)
                    Text("Áp dụng cho mọi dòng iPhone & iPad (iOS 14.0 - 18.x+)")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.12))
                .cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.blue.opacity(0.3), lineWidth: 1))
                
                // Cách 1: TrollStore
                guideSection(
                    title: "1. Dành Cho Máy Có TrollStore",
                    badge: "1-Click Tự Động",
                    badgeColor: .green,
                    icon: "bolt.fill",
                    steps: [
                        "Cài file app trực tiếp qua TrollStore.",
                        "Mở app, đăng nhập tài khoản để xác thực API Key từ máy chủ VPS 103.238.234.204.",
                        "Tùy chỉnh màu súng hoặc tải lên file cache của bạn.",
                        "Bấm nút 'CÀI ĐẶT TRỰC TIẾP VÀO GAME'.",
                        "Hệ thống sẽ tự động phát hiện thư mục Free Fire và thay thế chuẩn xác 100%!"
                    ]
                )
                
                // Cách 2: Files App
                guideSection(
                    title: "2. Chép Thủ Công Bằng Ứng Dụng Tệp",
                    badge: "Không Cần Jailbreak",
                    badgeColor: .blue,
                    icon: "folder.fill",
                    steps: [
                        "Trong app Build File, bấm nút 'XUẤT & LƯU TỆP'.",
                        "Chọn lưu vào thư mục 'Trên iPhone (On My iPhone)'.",
                        "Mở ứng dụng Tệp (Files) trên iOS.",
                        "Đối với Shaders: Chép file đè vào: Trên iPhone -> Free Fire (hoặc Free Fire MAX) -> Documents.",
                        "Đối với Hitbox: Chép file đè vào thư mục cache của Free Fire.",
                        "Mở lại game và thưởng thức hiệu ứng mới!"
                    ]
                )
                
                // Cách 3: Sideloadly / Esign
                guideSection(
                    title: "3. Cài Đặt File IPA",
                    badge: "Sideload",
                    badgeColor: .purple,
                    icon: "arrow.down.doc.fill",
                    steps: [
                        "Tải file RegMod.ipa từ GitHub Releases hoặc Actions.",
                        "Dùng máy tính qua Sideloadly / AltStore hoặc chứng chỉ trực tiếp trên điện thoại qua Esign / Scarlet.",
                        "Ký và cài đặt ứng dụng vào máy.",
                        "Vào Cài đặt iOS -> Cài đặt chung -> Quản lý VPN & Thiết bị -> Tin cậy chứng chỉ để mở app."
                    ]
                )
            }
            .padding()
        }
        .background(theme.backgroundColor.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(loc.t("tab_guide"))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
            }
        }
    }
    
    private func guideSection(title: String, badge: String, badgeColor: Color, icon: String, steps: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(badgeColor)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                Spacer()
                Text(badge)
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(badgeColor.opacity(0.2))
                    .foregroundColor(badgeColor)
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(idx + 1).")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.cyan)
                            .frame(width: 16, alignment: .leading)
                        Text(step)
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                    }
                }
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.cardBorder, lineWidth: 1))
    }
}
