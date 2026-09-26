import SwiftUI

public struct AdminBlacklistView: View {
    @ObservedObject var api = AdminAPIService.shared
    @State private var newHWID: String = ""
    @State private var newReason: String = "Chặn qua App Admin"
    @State private var showAddModal: Bool = false
    @State private var copiedHWID: String? = nil
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 14) {
            // Header with Add Button
            HStack {
                Text("DANH SÁCH HWID BỊ CHẶN (\(api.blacklist.count))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                Spacer()
                Button(action: { showAddModal = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Chặn HWID Mới")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            if api.blacklist.isEmpty {
                VStack(spacing: 12) {
                    Spacer().frame(height: 50)
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green.opacity(0.6))
                    Text("Hiện chưa có thiết bị nào bị chặn")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(api.blacklist) { item in
                            blacklistCard(item)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $showAddModal) {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.09).ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("CHẶN THIẾT BỊ (HWID)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("MÃ HWID THIẾT BỊ")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        TextField("Nhập chuỗi HWID cần chặn...", text: $newHWID)
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("LÝ DO CHẶN")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        TextField("Lý do...", text: $newReason)
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 16) {
                        Button("Hủy") { showAddModal = false }
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                        
                        Button(action: {
                            let hw = newHWID.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !hw.isEmpty {
                                api.blockHWID(hwid: hw, reason: newReason) { _ in
                                    newHWID = ""
                                    showAddModal = false
                                }
                            }
                        }) {
                            Text("Xác Nhận Chặn")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
        }
    }
    
    private func blacklistCard(_ item: AdminBlacklistItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "slash.circle.fill")
                    .foregroundColor(.red)
                
                Text(item.hwid)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Button(action: {
                    UIPasteboard.general.string = item.hwid
                    copiedHWID = item.hwid
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if copiedHWID == item.hwid { copiedHWID = nil }
                    }
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: copiedHWID == item.hwid ? "checkmark" : "doc.on.doc")
                        Text(copiedHWID == item.hwid ? "Đã copy" : "Copy")
                    }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(copiedHWID == item.hwid ? .green : .cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.cyan.opacity(0.15))
                    .cornerRadius(6)
                }
                
                Spacer()
                
                Button(action: {
                    api.unblockHWID(hwid: item.hwid) { _ in }
                }) {
                    Text("Bỏ Chặn")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(8)
                }
            }
            
            if let reason = item.reason, !reason.isEmpty {
                Text("Lý do: \(reason)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if let blocked = item.blocked_at, !blocked.isEmpty {
                Text("Thời gian: \(blocked)")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.7))
            }
        }
        .padding(14)
        .background(Color(red: 0.08, green: 0.10, blue: 0.14))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.25), lineWidth: 1))
    }
}
