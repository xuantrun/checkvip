import SwiftUI

public struct AdminLogsView: View {
    @ObservedObject var api = AdminAPIService.shared
    @State private var copiedHWID: String? = nil
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("NHẬT KÝ ĐĂNG NHẬP GẦN ĐÂY (\(api.logs.count))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.gray)
                Spacer()
                Button(action: { api.fetchData() }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.cyan)
                }
            }
            .padding(.horizontal)
            
            if api.logs.isEmpty {
                VStack(spacing: 12) {
                    Spacer().frame(height: 50)
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("Chưa có nhật ký hoạt động nào")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(api.logs) { log in
                            logCard(log)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
        }
    }
    
    private func logCard(_ log: AdminLogItem) -> some View {
        let isSuccess = log.status?.lowercased().contains("thành công") ?? (log.status == "Success")
        return HStack(spacing: 12) {
            Circle()
                .fill(isSuccess ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(log.username ?? "Unknown")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(log.status ?? "")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isSuccess ? .green : .red)
                }
                
                HStack {
                    if let ip = log.ip ?? log.ip_address, !ip.isEmpty {
                        Text("IP: \(ip)")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    if let hwid = log.hwid, !hwid.isEmpty {
                        Button(action: {
                            UIPasteboard.general.string = hwid
                            copiedHWID = hwid
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                if copiedHWID == hwid { copiedHWID = nil }
                            }
                        }) {
                            HStack(spacing: 2) {
                                Image(systemName: copiedHWID == hwid ? "checkmark" : "doc.on.doc")
                                Text(copiedHWID == hwid ? "Đã copy" : "Copy HWID")
                            }
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(copiedHWID == hwid ? .green : .cyan)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.cyan.opacity(0.12))
                            .cornerRadius(4)
                        }
                    }
                    Spacer()
                    if let ts = log.timestamp {
                        Text(ts)
                            .font(.system(size: 9))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                }
            }
        }
        .padding(12)
        .background(Color(red: 0.08, green: 0.10, blue: 0.14))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}
