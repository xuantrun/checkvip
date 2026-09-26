import SwiftUI

public struct AdminLogsView: View {
    @ObservedObject private var api = AdminAPIService.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var search = ""
    @State private var copied: Int?
    public init() {}
    private var logs: [AdminLogItem] {
        api.logs.filter { search.isEmpty || ($0.username ?? "").localizedCaseInsensitiveContains(search) || ($0.status ?? "").localizedCaseInsensitiveContains(search) || ($0.hwid ?? "").localizedCaseInsensitiveContains(search) }
    }
    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                StudioHero(eyebrow: "ADMIN / ACTIVITY", title: "Hoạt động gần đây.", subtitle: "Tra cứu các lượt đăng nhập và trạng thái được máy chủ ghi nhận.", icon: "clock.arrow.circlepath")
                StudioFloatingField(title: "Tìm tài khoản, HWID hoặc trạng thái", icon: "magnifyingglass", text: $search)
                HStack {
                    Text("\(logs.count) bản ghi").font(.headline)
                    Spacer()
                    Button { api.fetchData() } label: { Label("Làm mới", systemImage: "arrow.clockwise").frame(minHeight: 44) }.disabled(api.isRefreshing)
                }
                if api.isRefreshing { ProgressView("Đang cập nhật nhật ký…").padding() }
                if let error = api.refreshError { Text(error).font(.subheadline).foregroundColor(.orange) }
                if logs.isEmpty && !api.isRefreshing && api.refreshError == nil {
                    StudioEmptyState(title: "Chưa có hoạt động phù hợp", message: "Nhật ký mới sẽ xuất hiện sau khi đồng bộ với máy chủ.", icon: "clock")
                }
                ForEach(logs) { log in
                    StudioPanel(log.username ?? "Không rõ tài khoản", icon: "person.crop.circle") {
                        Text(log.status ?? "Chưa có trạng thái").font(.subheadline.weight(.medium))
                        if let date = log.timestamp { Label(date, systemImage: "clock").font(.caption).foregroundColor(theme.secondaryText) }
                        if let ip = log.ip_address { Label(ip, systemImage: "network").font(.caption.monospaced()).foregroundColor(theme.secondaryText) }
                        if let hwid = log.hwid, !hwid.isEmpty {
                            HStack {
                                Text(hwid).font(.caption.monospaced()).lineLimit(1).truncationMode(.middle).foregroundColor(theme.secondaryText)
                                Spacer()
                                Button { UIPasteboard.general.string = hwid; copied = log.id } label: {
                                    Image(systemName: copied == log.id ? "checkmark" : "doc.on.doc").frame(width: 44, height: 44)
                                }.accessibilityLabel("Sao chép HWID")
                            }
                        }
                    }
                }
            }.padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(theme.backgroundColor.ignoresSafeArea()).foregroundColor(theme.primaryText)
    }
}
