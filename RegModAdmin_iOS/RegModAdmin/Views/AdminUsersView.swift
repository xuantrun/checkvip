import SwiftUI

public struct AdminUsersView: View {
    @ObservedObject private var api = AdminAPIService.shared
    @ObservedObject private var theme = ThemeManager.shared
    public var filterRole: Int? = nil
    public var filterVIPOnly = false
    @State private var search = ""
    @State private var roleFilter = -1
    @State private var showingAdd = false
    @State private var deleting: AdminUserItem?
    @State private var confirmDelete = false
    @State private var busyUser: String?
    @State private var feedback = ""
    @State private var failed = false
    @State private var newName = ""
    @State private var newPassword = ""
    @State private var newHWID = ""
    @State private var newRole = 0
    @State private var submitting = false
    @State private var formError = ""
    @State private var quickName = ""
    @State private var quickRole = 1
    public init(filterRole: Int? = nil, filterVIPOnly: Bool = false) {
        self.filterRole = filterRole; self.filterVIPOnly = filterVIPOnly
    }
    private var users: [AdminUserItem] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return api.users.filter { user in
            let role = filterRole ?? roleFilter
            return (role < 0 || (role == 2 ? user.role >= 2 : user.role == role)) && (!filterVIPOnly || user.role >= 1) &&
                (query.isEmpty || user.username.localizedCaseInsensitiveContains(query) || (user.hwid ?? "").localizedCaseInsensitiveContains(query))
        }
    }
    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                StudioHero(eyebrow: "ADMIN / PEOPLE", title: "Quản lý tài khoản.", subtitle: "Tìm kiếm, cấp quyền và theo dõi trạng thái từng thành viên.", icon: "person.2")
                HStack {
                    Image(systemName: "magnifyingglass").foregroundColor(theme.secondaryText)
                    TextField("Tìm tài khoản hoặc HWID", text: $search).textInputAutocapitalization(.never).disableAutocorrection(true)
                    if !search.isEmpty { Button { search = "" } label: { Image(systemName: "xmark.circle.fill").frame(width: 44, height: 44) }.accessibilityLabel("Xóa tìm kiếm") }
                }.padding(.horizontal, 16).frame(minHeight: 56).background(theme.cardBackground).cornerRadius(18)
                Picker("Quyền tài khoản", selection: $roleFilter) {
                    Text("Tất cả").tag(-1); Text("Free").tag(0); Text("VIP 1").tag(1); Text("VIP 2").tag(2)
                }.pickerStyle(.segmented)
                if !feedback.isEmpty {
                    Label(feedback, systemImage: failed ? "exclamationmark.circle" : "checkmark.circle")
                        .font(.subheadline).foregroundColor(failed ? .red : .green).frame(maxWidth: .infinity, alignment: .leading)
                }
                StudioDisclosure("Cấp VIP nhanh") {
                    StudioFloatingField(title: "Tên tài khoản", icon: "person", text: $quickName)
                    Picker("Gói VIP", selection: $quickRole) { Text("VIP 1").tag(1); Text("VIP 2").tag(2) }.pickerStyle(.segmented)
                    Button("Cấp quyền VIP") {
                        let name = quickName.trimmingCharacters(in: .whitespacesAndNewlines)
                        busyUser = name
                        api.setUserRole(username: name, role: quickRole) { success in report(success, "Đã cập nhật quyền cho \(name)") }
                    }.buttonStyle(StudioActionStyle()).disabled(busyUser != nil || quickName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                HStack {
                    Text("\(users.count) tài khoản").font(.headline)
                    Spacer()
                    Button {
                        newName = ""; newPassword = ""; newHWID = ""; newRole = max(roleFilter, 0); formError = ""; showingAdd = true
                    } label: { Label("Thêm mới", systemImage: "plus").frame(minHeight: 44) }
                }
                if api.isRefreshing && api.lastRefreshed == nil {
                    ProgressView("Đang tải tài khoản…").padding(24)
                } else if let error = api.refreshError, api.lastRefreshed == nil {
                    StudioEmptyState(title: "Chưa tải được tài khoản", message: error, icon: "wifi.exclamationmark")
                    Button("Thử lại") { api.fetchData() }.buttonStyle(StudioActionStyle())
                } else if users.isEmpty {
                    StudioEmptyState(title: "Chưa có kết quả", message: search.isEmpty ? "Tài khoản mới sẽ xuất hiện tại đây." : "Thử tên khác hoặc đổi bộ lọc quyền.", icon: "person.crop.circle.badge.questionmark")
                } else {
                    ForEach(users) { user in userCard(user) }
                }
            }.padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(theme.backgroundColor.ignoresSafeArea()).foregroundColor(theme.primaryText)
        .sheet(isPresented: $showingAdd) { addSheet }
        .alert("Xóa tài khoản?", isPresented: $confirmDelete) {
            Button("Xóa", role: .destructive) {
                if let user = deleting {
                    busyUser = user.username
                    api.deleteUser(username: user.username) { success in report(success, "Đã xóa \(user.username)") }
                }
            }
            Button("Hủy", role: .cancel) {}
        } message: { Text("Tài khoản \(deleting?.username ?? "") sẽ bị xóa. Thao tác này không thể hoàn tác.") }
    }
    private func userCard(_ user: AdminUserItem) -> some View {
        StudioPanel(user.username, icon: user.is_blocked == 1 ? "lock" : "person.crop.circle") {
            HStack {
                Text(user.role >= 2 ? "VIP 2" : (user.role == 1 ? "VIP 1" : "Free"))
                    .font(.caption.bold()).padding(.horizontal, 12).padding(.vertical, 6).background(theme.accentColor.opacity(0.1)).clipShape(Capsule())
                Spacer()
                Label(user.is_blocked == 1 ? "Đã khóa" : "Hoạt động", systemImage: user.is_blocked == 1 ? "lock.fill" : "checkmark.circle")
                    .font(.caption).foregroundColor(user.is_blocked == 1 ? .orange : .green)
            }
            if let hwid = user.hwid, !hwid.isEmpty {
                HStack {
                    Text(hwid).font(.caption.monospaced()).lineLimit(1).truncationMode(.middle).foregroundColor(theme.secondaryText)
                    Spacer()
                    Button { UIPasteboard.general.string = hwid; failed = false; feedback = "Đã sao chép HWID" } label: {
                        Image(systemName: "doc.on.doc").frame(width: 44, height: 44)
                    }.accessibilityLabel("Sao chép mã thiết bị")
                }
            }
            if let login = user.last_login { Text("Lần đăng nhập: \(login)").font(.caption).foregroundColor(theme.secondaryText) }
            HStack {
                Menu {
                    ForEach(0..<3) { role in
                        Button(role == 0 ? "Free" : "VIP \(role)") {
                            busyUser = user.username
                            api.setUserRole(username: user.username, role: role) { success in report(success, "Đã đổi quyền \(user.username)") }
                        }
                    }
                } label: { Label("Đổi quyền", systemImage: "crown").frame(minHeight: 44) }
                Spacer()
                Menu {
                    Button(user.is_blocked == 1 ? "Mở khóa" : "Khóa tài khoản") {
                        busyUser = user.username
                        api.toggleUser(username: user.username) { success in report(success, "Đã cập nhật trạng thái \(user.username)") }
                    }
                    if let hwid = user.hwid, !hwid.isEmpty {
                        Button("Chặn thiết bị") {
                            busyUser = user.username
                            api.blockHWID(hwid: hwid, reason: "Chặn từ tài khoản \(user.username)") { success in report(success, "Đã chặn thiết bị") }
                        }
                    }
                    Button("Xóa tài khoản", role: .destructive) { deleting = user; confirmDelete = true }
                } label: { Image(systemName: "ellipsis.circle").frame(width: 44, height: 44) }.accessibilityLabel("Thao tác tài khoản")
                if busyUser == user.username { ProgressView() }
            }.disabled(busyUser != nil)
        }
    }
    private var addSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 22) {
                    StudioHero(eyebrow: "ADMIN / NEW ACCOUNT", title: "Thành viên mới.", subtitle: "Nhập thông tin và chọn quyền truy cập ban đầu.", icon: "person.badge.plus")
                    StudioPanel("Thông tin đăng nhập", icon: "person") {
                        StudioFloatingField(title: "Tên tài khoản", icon: "person", text: $newName)
                        StudioFloatingField(title: "Mật khẩu", icon: "lock", text: $newPassword, secure: true)
                        StudioFloatingField(title: "HWID (không bắt buộc)", icon: "cpu", text: $newHWID)
                    }
                    StudioPanel("Quyền truy cập", icon: "key") {
                        Picker("Quyền", selection: $newRole) { Text("Free").tag(0); Text("VIP 1").tag(1); Text("VIP 2").tag(2) }.pickerStyle(.segmented)
                        Text(newRole == 2 ? "Shader, Cache và Avatar" : (newRole == 1 ? "Shader và Cache" : "Cache theo chế độ máy chủ"))
                            .font(.subheadline).foregroundColor(theme.secondaryText)
                    }
                    if !formError.isEmpty { Text(formError).font(.subheadline).foregroundColor(.red) }
                    Button {
                        submitting = true; formError = ""
                        api.addUser(username: newName.trimmingCharacters(in: .whitespacesAndNewlines), password: newPassword, role: newRole, hwid: newHWID.trimmingCharacters(in: .whitespacesAndNewlines)) { success, error in
                            submitting = false
                            if success { showingAdd = false; failed = false; feedback = "Đã thêm tài khoản mới" }
                            else { formError = error ?? "Không thể tạo tài khoản. Vui lòng thử lại." }
                        }
                    } label: { HStack { if submitting { ProgressView() }; Text(submitting ? "Đang tạo tài khoản…" : "Tạo tài khoản") } }
                        .buttonStyle(StudioActionStyle()).disabled(submitting || newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newPassword.isEmpty)
                }.padding(20).frame(maxWidth: 640).frame(maxWidth: .infinity)
                    .disabled(submitting)
            }.background(theme.backgroundColor.ignoresSafeArea()).foregroundColor(theme.primaryText)
                .navigationTitle("Thêm tài khoản").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Đóng") { showingAdd = false }.disabled(submitting) } }
        }.navigationViewStyle(.stack).interactiveDismissDisabled(submitting)
    }
    private func report(_ success: Bool, _ message: String) {
        busyUser = nil; failed = !success
        feedback = success ? message : "Thao tác thất bại. Vui lòng thử lại."
    }
}
