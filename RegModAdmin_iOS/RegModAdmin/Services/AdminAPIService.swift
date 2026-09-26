import Foundation
import SwiftUI
import Combine

public struct AdminUserItem: Identifiable, Codable {
    public var id: String { username }
    public let username: String
    public let created_at: String?
    public let last_login: String?
    public let last_ip: String?
    public let hwid: String?
    public var is_blocked: Int
    public var role: Int
}

public struct AdminBlacklistItem: Identifiable, Codable {
    public var id: String { hwid }
    public let hwid: String
    public let reason: String?
    public let blocked_at: String?
}

public struct AdminLogItem: Identifiable, Codable {
    public let id: Int
    public let username: String?
    public let hwid: String?
    public let ip: String?
    public var ip_address: String? { ip }
    public let timestamp: String?
    public let status: String?
}

public class AdminAPIService: ObservableObject {
    public static let shared = AdminAPIService()
    
    // Obfuscated Base64 VPS Host: http://103.238.234.204:5678
    private let obfuscatedHostB64 = "aHR0cDovLzEwMy4yMzguMjM0LjIwNDo1Njc4"
    public var serverURL: String {
        guard let data = Data(base64Encoded: obfuscatedHostB64),
              let decoded = String(data: data, encoding: .utf8) else {
            return "http://127.0.0.1:5678"
        }
        return decoded
    }
    
    @Published public var isAuthenticated: Bool = false
    @Published public var adminKey: String = "222007"
    @Published public var isOnline: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var isRefreshing = false
    @Published public var refreshError: String? = nil
    
    @Published public var users: [AdminUserItem] = []
    @Published public var blacklist: [AdminBlacklistItem] = []
    @Published public var logs: [AdminLogItem] = []
    @Published public var activeCount: Int = 0
    @Published public var lastRefreshed: Date? = nil
    @Published public var isFreeCacheEnabled: Bool = true
    
    private init() {
        checkHealth()
    }
    
    public func checkHealth(completion: ((Bool) -> Void)? = nil) {
        guard let url = URL(string: "\(serverURL)/api/v1/health") else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 4.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                let online = (error == nil && (response as? HTTPURLResponse)?.statusCode == 200)
                self?.isOnline = online
                completion?(online)
            }
        }.resume()
    }
    
    public func login(password: String, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        guard let url = URL(string: "\(serverURL)/meonxt/login") else {
            isLoading = false
            completion(false, "Lỗi địa chỉ máy chủ")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 6.0
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["password": password])
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    completion(false, "Không thể kết nối đến máy chủ: \(error.localizedDescription)")
                    return
                }
                guard let http = response as? HTTPURLResponse else {
                    completion(false, "Lỗi giao thức kết nối")
                    return
                }
                if http.statusCode == 200 {
                    self?.isAuthenticated = true
                    self?.adminKey = password
                    self?.isOnline = true
                    completion(true, nil)
                } else {
                    completion(false, "Mật khẩu quản trị không chính xác.")
                }
            }
        }.resume()
    }
    
    public func logout() {
        isAuthenticated = false
        users = []
        blacklist = []
        logs = []
        lastRefreshed = nil
        refreshError = nil
    }
    
    public func fetchData(completion: ((Bool) -> Void)? = nil) {
        guard !isRefreshing else { completion?(false); return }
        guard let url = URL(string: "\(serverURL)/meonxt/api/data") else {
            refreshError = "Địa chỉ máy chủ không hợp lệ."
            completion?(false)
            return
        }
        isRefreshing = true
        refreshError = nil
        var request = URLRequest(url: url)
        request.setValue(adminKey, forHTTPHeaderField: "X-Admin-Key")
        request.timeoutInterval = 8.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isRefreshing = false
                guard self?.isAuthenticated == true else { completion?(false); return }
                if let http = response as? HTTPURLResponse, http.statusCode == 401 || http.statusCode == 403 {
                    self?.logout()
                    completion?(false)
                    return
                }
                guard let data = data, error == nil,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let success = json["success"] as? Bool, success else {
                    self?.isOnline = false
                    self?.refreshError = "Không thể tải dữ liệu. Hãy thử lại."
                    completion?(false)
                    return
                }
                
                self?.isOnline = true
                self?.lastRefreshed = Date()
                
                // Parse users
                if let usersArr = json["users"] as? [[String: Any]] {
                    self?.users = usersArr.compactMap { dict in
                        guard let u = dict["username"] as? String else { return nil }
                        let r = (dict["role"] as? Int) ?? 0
                        return AdminUserItem(
                            username: u,
                            created_at: dict["created_at"] as? String,
                            last_login: dict["last_login"] as? String,
                            last_ip: dict["last_ip"] as? String,
                            hwid: dict["hwid"] as? String,
                            is_blocked: (dict["is_blocked"] as? Int) ?? 0,
                            role: r
                        )
                    }
                }
                
                // Parse blacklist
                if let blArr = json["blacklist"] as? [[String: Any]] {
                    self?.blacklist = blArr.compactMap { dict in
                        guard let h = dict["hwid"] as? String else { return nil }
                        return AdminBlacklistItem(
                            hwid: h,
                            reason: dict["reason"] as? String,
                            blocked_at: dict["blocked_at"] as? String
                        )
                    }
                }
                
                // Parse logs
                if let logsArr = json["logs"] as? [[String: Any]] {
                    self?.logs = logsArr.enumerated().compactMap { index, dict in
                        let logId = (dict["id"] as? Int) ?? index
                        let ip = (dict["ip"] as? String) ?? (dict["ip_address"] as? String)
                        return AdminLogItem(
                            id: logId,
                            username: dict["username"] as? String,
                            hwid: dict["hwid"] as? String,
                            ip: ip,
                            timestamp: dict["timestamp"] as? String,
                            status: dict["status"] as? String
                        )
                    }
                }
                
                self?.activeCount = (json["active_keys_count"] as? Int) ?? 0
                if let freeEn = json["free_cache_enabled"] as? Bool {
                    self?.isFreeCacheEnabled = freeEn
                }
                completion?(true)
            }
        }.resume()
    }
    
    public func toggleUser(username: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(serverURL)/meonxt/api/toggle_user") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(adminKey, forHTTPHeaderField: "X-Admin-Key")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["username": username])
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                if error == nil {
                    self?.fetchData()
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    public func deleteUser(username: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(serverURL)/meonxt/api/delete_user") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(adminKey, forHTTPHeaderField: "X-Admin-Key")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["username": username])
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                if error == nil {
                    self?.fetchData()
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    public func blockHWID(hwid: String, reason: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(serverURL)/meonxt/api/block_hwid") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(adminKey, forHTTPHeaderField: "X-Admin-Key")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["hwid": hwid, "reason": reason])
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                if error == nil {
                    self?.fetchData()
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    public func unblockHWID(hwid: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(serverURL)/meonxt/api/unblock_hwid") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(adminKey, forHTTPHeaderField: "X-Admin-Key")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["hwid": hwid])
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                if error == nil {
                    self?.fetchData()
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    public func setUserRole(username: String, role: Int, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(serverURL)/meonxt/api/set_role") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(adminKey, forHTTPHeaderField: "X-Admin-Key")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["username": username, "role": role])
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                if error == nil {
                    self?.fetchData()
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }.resume()
    }
    
    public func addUser(username: String, password: String, role: Int, hwid: String = "", completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: "\(serverURL)/meonxt/api/add_user") else {
            completion(false, "Lỗi địa chỉ máy chủ")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(adminKey, forHTTPHeaderField: "X-Admin-Key")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "username": username,
            "password": password,
            "role": role,
            "hwid": hwid
        ])
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, error.localizedDescription)
                    return
                }
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let success = json["success"] as? Bool else {
                    completion(false, "Lỗi phản hồi máy chủ")
                    return
                }
                if success {
                    self?.fetchData()
                    completion(true, nil)
                } else {
                    let err = json["error"] as? String ?? "Không thể thêm tài khoản"
                    completion(false, err)
                }
            }
        }.resume()
    }
    
    public func toggleFreeCache(enabled: Bool? = nil, completion: ((Bool) -> Void)? = nil) {
        guard let url = URL(string: "\(serverURL)/meonxt/api/toggle_free_cache") else {
            completion?(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(adminKey, forHTTPHeaderField: "X-Admin-Key")
        
        var payload: [String: Any] = [:]
        if let en = enabled {
            payload["enabled"] = en
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let success = json["success"] as? Bool, success else {
                    completion?(false)
                    return
                }
                if let newEn = json["free_cache_enabled"] as? Bool {
                    self?.isFreeCacheEnabled = newEn
                }
                completion?(true)
            }
        }.resume()
    }
}
