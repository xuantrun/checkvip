import SwiftUI

public struct AdminDashboardView: View {
    @ObservedObject var api = AdminAPIService.shared
    @State private var selectedTab: Int = 0
    
    public init() {}
    
    private var vip1Count: Int {
        api.users.filter { $0.role == 1 }.count
    }
    
    private var vip2Count: Int {
        api.users.filter { $0.role >= 2 }.count
    }
    
    public var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.06, blue: 0.09).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Bar
                HStack(spacing: 12) {
                    Image("game_cover_fft")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MEONXT ADMIN")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.white)
                        HStack(spacing: 5) {
                            Circle()
                                .fill(api.isOnline ? Color.green : Color.red)
                                .frame(width: 6, height: 6)
                            Text(api.isOnline ? "Hệ Thống Sẵn Sàng" : "Mất Kết Nối")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(api.isOnline ? .green : .red)
                        }
                    }
                    
                    Spacer()
                    
                    // Refresh Button
                    Button(action: {
                        api.fetchData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    // Logout Button
                    Button(action: {
                        api.logout()
                    }) {
                        Image(systemName: "power")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color(red: 0.07, green: 0.08, blue: 0.12))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Không gian quản trị").font(.title2.bold()).foregroundColor(.white)
                    if api.isRefreshing {
                        HStack(spacing: 8) {
                            ProgressView().tint(.cyan)
                            Text("Đang đồng bộ dữ liệu…").font(.caption).foregroundColor(.gray)
                        }
                    } else if let error = api.refreshError {
                        HStack {
                            Text(error).font(.caption).foregroundColor(.orange)
                            Spacer()
                            Button("Thử lại") { api.fetchData() }
                        }
                    } else if let updated = api.lastRefreshed {
                        HStack(spacing: 4) {
                            Text("Cập nhật lúc")
                            Text(updated, style: .time)
                        }.font(.caption).foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20).padding(.vertical, 16)

                // Stats Counter Grid
                ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    statCard(title: "USER", count: "\(api.users.count)", color: .cyan, icon: "person.2.fill")
                    statCard(title: "VIP 2", count: "\(vip2Count)", color: .purple, icon: "crown.fill")
                    statCard(title: "VIP 1", count: "\(vip1Count)", color: .yellow, icon: "wand.and.stars")
                    statCard(title: "CHẶN", count: "\(api.blacklist.count)", color: .red, icon: "slash.circle.fill")
                    statCard(title: "LOGS", count: "\(api.logs.count)", color: .orange, icon: "doc.text.fill")
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                }

                // Free Cache Global Switch Banner
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(api.isFreeCacheEnabled ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text("FREE CACHE: \(api.isFreeCacheEnabled ? "ĐANG BẬT" : "ĐÃ ĐÓNG")")
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(api.isFreeCacheEnabled ? .green : .red)
                        }
                        Text(api.isFreeCacheEnabled ? "Mọi user Free đều được Make Cache" : "Chỉ VIP mới được Make (User Free bị chặn)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        api.toggleFreeCache()
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: api.isFreeCacheEnabled ? "lock.fill" : "lock.open.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text(api.isFreeCacheEnabled ? "Đóng Free" : "Mở Free")
                                .font(.system(size: 12, weight: .black))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(api.isFreeCacheEnabled ? Color.red.opacity(0.85) : Color.green.opacity(0.85))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(red: 0.08, green: 0.10, blue: 0.14))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(api.isFreeCacheEnabled ? Color.green.opacity(0.3) : Color.red.opacity(0.3), lineWidth: 1))
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Filters remain readable on compact screens.
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip("Tất cả", tab: 0)
                        filterChip("VIP 2", tab: 1)
                        filterChip("VIP 1", tab: 2)
                        filterChip("Thiết bị chặn", tab: 3)
                        filterChip("Nhật ký", tab: 4)
                    }.padding(.horizontal).padding(.vertical, 10)
                }

                // Selected Tab Content
                Group {
                    switch selectedTab {
                    case 0:
                        AdminUsersView(filterRole: nil)
                    case 1:
                        AdminUsersView(filterRole: 2)
                    case 2:
                        AdminUsersView(filterRole: 1)
                    case 3:
                        AdminBlacklistView()
                    default:
                        AdminLogsView()
                    }
                }
            }
        }
        .onAppear {
            api.fetchData()
        }
    }
    
    private func filterChip(_ title: String, tab: Int) -> some View {
        Button { selectedTab = tab } label: {
            Text(title).font(.subheadline.weight(.semibold))
                .foregroundColor(selectedTab == tab ? .black : .white)
                .padding(.horizontal, 16).frame(minHeight: 44)
                .background(selectedTab == tab ? Color.cyan : Color.white.opacity(0.07))
                .clipShape(Capsule())
        }
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
    }

    private func statCard(title: String, count: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(api.lastRefreshed == nil ? "—" : count)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 7.5, weight: .bold))
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .padding(14)
        .frame(minWidth: 100, alignment: .leading)
        .background(Color(red: 0.08, green: 0.10, blue: 0.14))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}
