import SwiftUI

public struct AdminBlacklistView: View {
    @ObservedObject private var api = AdminAPIService.shared
    @ObservedObject private var theme = ThemeManager.shared
    @State private var search = ""
    @State private var newHWID = ""
    @State private var reason = ""
    @State private var showAdd = false
    @State private var submitting = false
    @State private var pendingHWID: String?
    @State private var message = ""
    @State private var formError = ""
    public init() {}
    private var devices: [AdminBlacklistItem] {
        api.blacklist.filter { search.isEmpty || $0.hwid.localizedCaseInsensitiveContains(search) || ($0.reason ?? "").localizedCaseInsensitiveContains(search) }
    }
    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                StudioHero(eyebrow: "ADMIN / DEVICES", title: "Kiểm soát truy cập.", subtitle: "Quản lý các thiết bị bị chặn và lý do hạn chế truy cập.", icon: "shield.lefthalf.filled")
                StudioFloatingField(title: "Tìm mã thiết bị hoặc lý do", icon: "magnifyingglass", text: $search)
                Button { newHWID = ""; reason = ""; formError = ""; showAdd = true } label: {
                    Label("Chặn thiết bị mới", systemImage: "plus")
                }.buttonStyle(StudioActionStyle())
                if !message.isEmpty { Text(message).font(.subheadline).foregroundColor(theme.secondaryText) }
                if api.isRefreshing && api.lastRefreshed == nil {
                    ProgressView("Đang tải thiết bị…").padding()
                } else if let error = api.refreshError, api.lastRefreshed == nil {
                    StudioEmptyState(title: "Chưa tải được thiết bị", message: error, icon: "wifi.exclamationmark")
                    Button("Thử lại") { api.fetchData() }.buttonStyle(StudioActionStyle())
                } else if devices.isEmpty {
                    StudioEmptyState(title: search.isEmpty ? "Không có thiết bị bị chặn" : "Không tìm thấy thiết bị", message: search.isEmpty ? "Danh sách thiết bị bị hạn chế sẽ xuất hiện tại đây." : "Thử tìm bằng mã thiết bị hoặc lý do khác.", icon: "checkmark.shield")
                } else {
                    ForEach(devices) { device in
                        StudioPanel("Thiết bị bị chặn", icon: "lock.shield") {
                            Text(device.hwid).font(.subheadline.monospaced()).textSelection(.enabled)
                            Text(device.reason ?? "Chưa có lý do").font(.subheadline).foregroundColor(theme.secondaryText)
                            if let date = device.blocked_at { Text(date).font(.caption).foregroundColor(theme.secondaryText) }
                            HStack {
                                Button { UIPasteboard.general.string = device.hwid; message = "Đã sao chép mã thiết bị" } label: { Label("Sao chép", systemImage: "doc.on.doc").frame(minHeight: 44) }
                                Spacer()
                                Button {
                                    pendingHWID = device.hwid
                                    api.unblockHWID(hwid: device.hwid) { success in
                                        pendingHWID = nil
                                        message = success ? "Đã bỏ chặn thiết bị" : "Không thể bỏ chặn. Vui lòng thử lại."
                                    }
                                } label: {
                                    HStack { if pendingHWID == device.hwid { ProgressView() }; Text("Bỏ chặn") }.frame(minHeight: 44)
                                }.disabled(pendingHWID != nil)
                            }
                        }
                    }
                }
            }.padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(theme.backgroundColor.ignoresSafeArea()).foregroundColor(theme.primaryText)
            .sheet(isPresented: $showAdd) { addSheet }
    }
    private var addSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 22) {
                    StudioHero(eyebrow: "ADMIN / RESTRICT", title: "Chặn một thiết bị.", subtitle: "Thiết bị này sẽ không thể truy cập ứng dụng cho đến khi được bỏ chặn.", icon: "lock.shield")
                    StudioFloatingField(title: "Mã HWID thiết bị", icon: "cpu", text: $newHWID)
                    StudioFloatingField(title: "Lý do chặn", icon: "text.alignleft", text: $reason)
                    if !formError.isEmpty { Text(formError).foregroundColor(.red).font(.subheadline) }
                    Button {
                        submitting = true; formError = ""
                        api.blockHWID(hwid: newHWID.trimmingCharacters(in: .whitespacesAndNewlines), reason: reason) { success in
                            submitting = false
                            if success { showAdd = false; message = "Đã chặn thiết bị" }
                            else { formError = "Không thể chặn thiết bị. Kiểm tra kết nối rồi thử lại." }
                        }
                    } label: { HStack { if submitting { ProgressView() }; Text(submitting ? "Đang cập nhật…" : "Xác nhận chặn") } }
                        .buttonStyle(StudioActionStyle()).disabled(submitting || newHWID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }.padding(20).frame(maxWidth: 640).frame(maxWidth: .infinity).disabled(submitting)
            }.background(theme.backgroundColor.ignoresSafeArea()).foregroundColor(theme.primaryText)
                .navigationTitle("Chặn thiết bị").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Đóng") { showAdd = false }.disabled(submitting) } }
        }.navigationViewStyle(.stack).interactiveDismissDisabled(submitting)
    }
}
