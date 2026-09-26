import SwiftUI

public struct AdminUsersView: View {
    @ObservedObject var api = AdminAPIService.shared
    public var filterRole: Int? = nil // nil: Tất cả, 1: VIP 1, 2: VIP 2
    public var filterVIPOnly: Bool = false
    
    @State private var searchText: String = ""
    @State private var userToDelete: String? = nil
    @State private var showDeleteConfirm: Bool = false
    @State private var copiedHWID: String? = nil
    
    // Quick VIP Grant state
    @State private var quickVipUsername: String = ""
    @State private var quickVipRole: Int = 2 // 1: VIP 1 (Shader), 2: VIP 2 (Full Avt)
    @State private var isGrantingQuickVip: Bool = false
    @State private var statusToast: String? = nil
    
    // Add User Sheet
    @State private var showAddUserSheet: Bool = false
    @State private var newUsername: String = ""
    @State private var newPassword: String = ""
    @State private var newRole: Int = 0 // 0: Free, 1: VIP 1, 2: VIP 2
    @State private var newHwid: String = ""
    @State private var addError: String? = nil
    @State private var isSubmitting: Bool = false
    
    public init(filterRole: Int? = nil, filterVIPOnly: Bool = false) {
        self.filterRole = filterRole
        self.filterVIPOnly = filterVIPOnly
    }
    
    var filteredUsers: [AdminUserItem] {
        var list = api.users
        if let r = filterRole {
            list = list.filter { $0.role == r }
        } else if filterVIPOnly {
            list = list.filter { $0.role >= 1 }
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter { $0.username.localizedCaseInsensitiveContains(q) }
        }
        return list
    }
    
    public var body: some View {
        VStack(spacing: 10) {
            // Status feedback toast
            if let toast = statusToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text(toast)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { statusToast = nil }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.18))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.green.opacity(0.3), lineWidth: 1))
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Specialized VIP Banner when in VIP view
            if let r = filterRole {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(r == 2 ? Color.purple.opacity(0.2) : Color.yellow.opacity(0.2))
                            .frame(width: 32, height: 32)
                        Image(systemName: r == 2 ? "crown.fill" : "wand.and.stars")
                            .foregroundColor(r == 2 ? .purple : .yellow)
                            .font(.system(size: 14))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(r == 2 ? "DANH SÁCH ĐÃ CẤP VIP 2 (\(filteredUsers.count))" : "DANH SÁCH ĐÃ CẤP VIP 1 (\(filteredUsers.count))")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(r == 2 ? .purple : .yellow)
                        Text(r == 2 ? "Quyền VIP 2: Make Avatar (AssetIndexer) + Shader GunMod + Cache_res" : "Quyền VIP 1: Mở khóa Shader GunMod + Cache_res")
                            .font(.system(size: 9.5))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(10)
                .background(Color(red: 0.08, green: 0.07, blue: 0.09))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke((r == 2 ? Color.purple : Color.yellow).opacity(0.3), lineWidth: 1))
                .padding(.horizontal)
            }
            
            // QUICK VIP GRANT BOX (Always visible on ALL tabs: Tất Cả, VIP 1, VIP 2)
            VStack(spacing: 6) {
                // Role Selector for Quick VIP
                HStack(spacing: 8) {
                    Text("Cấp gói:")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(.gray)
                    
                    Button(action: { quickVipRole = 1 }) {
                        HStack(spacing: 4) {
                            Image(systemName: quickVipRole == 1 ? "checkmark.circle.fill" : "circle")
                            Text("⭐ VIP 1 (Shader)")
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(quickVipRole == 1 ? .black : .yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(quickVipRole == 1 ? Color.yellow : Color.yellow.opacity(0.12))
                        .cornerRadius(7)
                    }
                    
                    Button(action: { quickVipRole = 2 }) {
                        HStack(spacing: 4) {
                            Image(systemName: quickVipRole == 2 ? "checkmark.circle.fill" : "circle")
                            Text("👑 VIP 2 (Full Avt)")
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(quickVipRole == 2 ? .white : .purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(quickVipRole == 2 ? Color.purple : Color.purple.opacity(0.18))
                        .cornerRadius(7)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .foregroundColor(quickVipRole == 2 ? .purple : .yellow)
                            .font(.system(size: 12))
                        TextField("Nhập tên tài khoản cần cấp VIP...", text: $quickVipUsername)
                            .foregroundColor(.white)
                            .font(.system(size: 11))
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        if !quickVipUsername.isEmpty {
                            Button(action: { quickVipUsername = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(10)
                    
                    Button(action: grantQuickVip) {
                        HStack(spacing: 4) {
                            if isGrantingQuickVip {
                                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: quickVipRole == 2 ? "crown.fill" : "star.fill")
                                Text("Cấp VIP \(quickVipRole)")
                            }
                        }
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(quickVipRole == 2 ? .white : .black)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(quickVipRole == 2 ? Color.purple : Color.yellow)
                        .cornerRadius(10)
                    }
                    .disabled(isGrantingQuickVip || quickVipUsername.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(10)
            .background(Color(red: 0.08, green: 0.07, blue: 0.09))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .padding(.horizontal)
            
            // Search & Add Button Bar
            HStack(spacing: 10) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField(filterVIPOnly ? "Tìm trong danh sách VIP..." : "Tìm kiếm tài khoản...", text: $searchText)
                        .foregroundColor(.white)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(9)
                .background(Color.white.opacity(0.06))
                .cornerRadius(10)
                
                // Add User Button
                Button(action: {
                    newUsername = ""
                    newPassword = ""
                    newRole = filterVIPOnly ? 1 : 0
                    newHwid = ""
                    addError = nil
                    showAddUserSheet = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: filterVIPOnly ? "crown.fill" : "person.badge.plus")
                        Text(filterVIPOnly ? "Thêm VIP" : "Thêm")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(filterVIPOnly ? .black : .white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(filterVIPOnly ? Color.yellow : Color.cyan.opacity(0.85))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            // List of Users
            if filteredUsers.isEmpty {
                VStack(spacing: 12) {
                    Spacer().frame(height: 35)
                    Image(systemName: filterVIPOnly ? "crown" : "person.crop.circle.badge.xmark")
                        .font(.system(size: 44))
                        .foregroundColor(.gray.opacity(0.45))
                    Text(filterVIPOnly ? "Chưa có tài khoản nào được cấp VIP" : (searchText.isEmpty ? "Chưa có tài khoản nào được tạo" : "Không tìm thấy tài khoản phù hợp"))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredUsers) { user in
                            userCard(user)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showAddUserSheet) {
            addUserSheetView
        }
        .alert(isPresented: $showDeleteConfirm) {
            Alert(
                title: Text("Xác Nhận Xóa Tài Khoản"),
                message: Text("Bạn có chắc chắn muốn xóa tài khoản '\(userToDelete ?? "")' khỏi hệ thống không? Thao tác này không thể hoàn tác."),
                primaryButton: .destructive(Text("Xóa Vĩnh Viễn")) {
                    if let u = userToDelete {
                        api.deleteUser(username: u) { success in
                            if success {
                                showToast("Đã xóa vĩnh viễn tài khoản '\(u)'")
                            }
                        }
                    }
                },
                secondaryButton: .cancel(Text("Hủy"))
            )
        }
    }
    
    // MARK: - Quick VIP Action
    private func grantQuickVip() {
        let u = quickVipUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !u.isEmpty else { return }
        isGrantingQuickVip = true
        let targetRole = quickVipRole
        
        api.setUserRole(username: u, role: targetRole) { success in
            isGrantingQuickVip = false
            if success {
                quickVipUsername = ""
                showToast("Đã cấp thành công VIP \(targetRole) cho tài khoản '\(u)'!")
            } else {
                showToast("Không thể cấp VIP (Hãy kiểm tra tài khoản đã tồn tại chưa)")
            }
        }
    }
    
    private func showToast(_ message: String) {
        withAnimation {
            statusToast = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation {
                if statusToast == message {
                    statusToast = nil
                }
            }
        }
    }
    
    // MARK: - User Card
    private func userCard(_ user: AdminUserItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: user.is_blocked == 1 ? "lock.fill" : (user.role >= 2 ? "crown.fill" : (user.role == 1 ? "star.fill" : "person.fill")))
                    .foregroundColor(user.is_blocked == 1 ? .red : (user.role >= 2 ? .purple : (user.role == 1 ? .yellow : .cyan)))
                    .frame(width: 28, height: 28)
                    .background(
                        user.is_blocked == 1 ? Color.red.opacity(0.15) :
                        (user.role >= 2 ? Color.purple.opacity(0.2) :
                        (user.role == 1 ? Color.yellow.opacity(0.15) : Color.cyan.opacity(0.15)))
                    )
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(user.username)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Role Badge (0: Free, 1: VIP 1, 2: VIP 2)
                        if user.role >= 2 {
                            Text("👑 VIP 2 (FULL)")
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple.opacity(0.3))
                                .foregroundColor(.purple)
                                .clipShape(Capsule())
                        } else if user.role == 1 {
                            Text("⭐ VIP 1 (SHADER)")
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.yellow.opacity(0.25))
                                .foregroundColor(.yellow)
                                .clipShape(Capsule())
                        } else {
                            Text("🛡️ FREE")
                                .font(.system(size: 8, weight: .black))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.gray)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(user.is_blocked == 1 ? "ĐANG BỊ KHÓA" : "HOẠT ĐỘNG")
                        .font(.system(size: 8.5, weight: .black))
                        .foregroundColor(user.is_blocked == 1 ? .red : .green)
                }
                
                Spacer()
                
                // Granular 3-Way Role Buttons (Free / VIP 1 / VIP 2)
                HStack(spacing: 3) {
                    // 0: Free
                    Button(action: {
                        if user.role != 0 {
                            api.setUserRole(username: user.username, role: 0) { success in
                                if success { showToast("Đã chuyển '\(user.username)' về Free") }
                            }
                        }
                    }) {
                        Text("Free")
                            .font(.system(size: 9, weight: user.role == 0 ? .black : .bold))
                            .foregroundColor(user.role == 0 ? .black : .gray)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(user.role == 0 ? Color.cyan : Color.white.opacity(0.06))
                            .cornerRadius(6)
                    }
                    
                    // 1: VIP 1
                    Button(action: {
                        if user.role != 1 {
                            api.setUserRole(username: user.username, role: 1) { success in
                                if success { showToast("Đã cấp VIP 1 cho '\(user.username)'") }
                            }
                        }
                    }) {
                        Text("⭐ V1")
                            .font(.system(size: 9, weight: user.role == 1 ? .black : .bold))
                            .foregroundColor(user.role == 1 ? .black : .yellow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(user.role == 1 ? Color.yellow : Color.yellow.opacity(0.12))
                            .cornerRadius(6)
                    }
                    
                    // 2: VIP 2
                    Button(action: {
                        if user.role != 2 {
                            api.setUserRole(username: user.username, role: 2) { success in
                                if success { showToast("Đã cấp VIP 2 cho '\(user.username)'") }
                            }
                        }
                    }) {
                        Text("👑 V2")
                            .font(.system(size: 9, weight: user.role == 2 ? .black : .bold))
                            .foregroundColor(user.role == 2 ? .white : .purple)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(user.role == 2 ? Color.purple : Color.purple.opacity(0.18))
                            .cornerRadius(6)
                    }
                }
                
                // Toggle Block Button
                Button(action: {
                    api.toggleUser(username: user.username) { success in
                        if success {
                            showToast(user.is_blocked == 1 ? "Đã mở khóa '\(user.username)'" : "Đã khóa '\(user.username)'")
                        }
                    }
                }) {
                    Text(user.is_blocked == 1 ? "Mở Khóa" : "Khóa")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(user.is_blocked == 1 ? .green : .orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background((user.is_blocked == 1 ? Color.green : Color.orange).opacity(0.15))
                        .cornerRadius(8)
                }
                
                // Delete Button
                Button(action: {
                    userToDelete = user.username
                    showDeleteConfirm = true
                }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                        .padding(6)
                        .background(Color.red.opacity(0.15))
                        .clipShape(Circle())
                }
            }
            
            Divider().background(Color.white.opacity(0.08))
            
            // Details Grid
            VStack(alignment: .leading, spacing: 5) {
                if let hwid = user.hwid, !hwid.isEmpty {
                    HStack {
                        Text("HWID:")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.gray)
                        Text(hwid)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.cyan)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        // Copy HWID Button
                        Button(action: {
                            UIPasteboard.general.string = hwid
                            copiedHWID = hwid
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                if copiedHWID == hwid { copiedHWID = nil }
                            }
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: copiedHWID == hwid ? "checkmark" : "doc.on.doc")
                                Text(copiedHWID == hwid ? "Đã copy" : "Copy HWID")
                            }
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(copiedHWID == hwid ? .green : .cyan)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.cyan.opacity(0.15))
                            .cornerRadius(6)
                        }
                    }
                }
                
                HStack {
                    if let ip = user.last_ip, !ip.isEmpty {
                        HStack(spacing: 4) {
                            Text("IP:")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(.gray)
                            Text(ip)
                                .font(.system(size: 9.5))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    if let dt = user.created_at, !dt.isEmpty {
                        HStack(spacing: 4) {
                            Text("Tạo:")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(.gray)
                            Text(dt)
                                .font(.system(size: 9.5))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(red: 0.08, green: 0.10, blue: 0.14))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(user.role == 1 ? Color.yellow.opacity(0.25) : Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    // MARK: - Add User Modal Sheet
    private var addUserSheetView: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.09).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Header info
                        HStack(spacing: 10) {
                            Image(systemName: newRole == 2 ? "crown.fill" : (newRole == 1 ? "star.fill" : "person.badge.plus"))
                                .font(.system(size: 24))
                                .foregroundColor(newRole == 2 ? .purple : (newRole == 1 ? .yellow : .cyan))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(newRole == 2 ? "THÊM TÀI KHOẢN VIP 2 (FULL)" : (newRole == 1 ? "THÊM TÀI KHOẢN VIP 1 (SHADER)" : "THÊM TÀI KHOẢN FREE"))
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(.white)
                                Text(newRole == 2 ? "Toàn quyền: Make Avatar Mod + Shader + Cache_res" : (newRole == 1 ? "Quyền VIP 1: Shader GunMod + Cache_res" : "Tài khoản Free: Mặc định chỉ dùng Cache_res"))
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color(red: 0.08, green: 0.10, blue: 0.14))
                        .cornerRadius(14)
                        .padding(.horizontal)
                        
                        // Input fields
                        VStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Tên Tài Khoản *")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.gray)
                                TextField("Nhập tên người dùng...", text: $newUsername)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .padding(12)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Mật Khẩu *")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.gray)
                                SecureField("Nhập mật khẩu...", text: $newPassword)
                                    .padding(12)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                            }
                            
                            // Role Selection
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Phân Quyền Ban Đầu *")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.gray)
                                
                                HStack(spacing: 8) {
                                    Button(action: { newRole = 0 }) {
                                        HStack {
                                            Image(systemName: newRole == 0 ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(newRole == 0 ? .cyan : .gray)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("0: Free")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(.white)
                                                Text("Cache_res")
                                                    .font(.system(size: 8.5))
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(8)
                                        .background(newRole == 0 ? Color.cyan.opacity(0.15) : Color.white.opacity(0.04))
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(newRole == 0 ? Color.cyan : Color.clear, lineWidth: 1))
                                    }
                                    
                                    Button(action: { newRole = 1 }) {
                                        HStack {
                                            Image(systemName: newRole == 1 ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(newRole == 1 ? .yellow : .gray)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("1: VIP 1")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(.white)
                                                Text("Shader")
                                                    .font(.system(size: 8.5))
                                                    .foregroundColor(.yellow.opacity(0.8))
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(8)
                                        .background(newRole == 1 ? Color.yellow.opacity(0.15) : Color.white.opacity(0.04))
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(newRole == 1 ? Color.yellow : Color.clear, lineWidth: 1))
                                    }
                                    
                                    Button(action: { newRole = 2 }) {
                                        HStack {
                                            Image(systemName: newRole == 2 ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(newRole == 2 ? .purple : .gray)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("2: VIP 2")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(.white)
                                                Text("Full Avt")
                                                    .font(.system(size: 8.5))
                                                    .foregroundColor(.purple.opacity(0.8))
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(8)
                                        .background(newRole == 2 ? Color.purple.opacity(0.2) : Color.white.opacity(0.04))
                                        .cornerRadius(8)
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(newRole == 2 ? Color.purple : Color.clear, lineWidth: 1))
                                    }
                                }
                            }
                            
                            // Optional HWID Field
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Mã HWID (Không bắt buộc)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.gray)
                                TextField("Nhập HWID nếu muốn gán trước...", text: $newHwid)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .padding(12)
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(Color(red: 0.08, green: 0.10, blue: 0.14))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        if let err = addError {
                            Text(err)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        // Submit Button
                        Button(action: submitNewUser) {
                            HStack {
                                if isSubmitting {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: newRole == 1 ? "crown.fill" : "person.badge.plus")
                                    Text(newRole == 1 ? "Tạo Tài Khoản & Cấp VIP Ngay" : "Tạo Tài Khoản Mới")
                                }
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(newRole == 1 ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                newRole == 1 ? Color.yellow : Color.cyan
                            )
                            .cornerRadius(12)
                        }
                        .disabled(isSubmitting || newUsername.trimmingCharacters(in: .whitespaces).isEmpty || newPassword.trimmingCharacters(in: .whitespaces).isEmpty)
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.top, 16)
                }
                .navigationTitle(newRole == 1 ? "Thêm Đã Cấp VIP" : "Thêm Tài Khoản")
                .navigationBarItems(
                    trailing: Button("Đóng") {
                        showAddUserSheet = false
                    }
                    .foregroundColor(.cyan)
                )
            }
        }
    }
    
    private func submitNewUser() {
        let u = newUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let h = newHwid.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !u.isEmpty, !p.isEmpty else { return }
        isSubmitting = true
        addError = nil
        
        api.addUser(username: u, password: p, role: newRole, hwid: h) { success, err in
            isSubmitting = false
            if success {
                showAddUserSheet = false
                showToast(newRole == 1 ? "Đã thêm tài khoản '\(u)' và cấp VIP thành công!" : "Đã tạo tài khoản '\(u)' thành công!")
            } else {
                addError = err ?? "Không thể thêm tài khoản"
            }
        }
    }
}
