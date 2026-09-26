import Foundation
import UIKit
import SwiftUI

public final class APIService: ObservableObject {
    public static let shared = APIService()
    
    // Obfuscated default server: http://103.238.234.204:5678
    // Decoded from base64 string "aHR0cDovLzEwMy4yMzguMjM0LjIwNDo1Njc4"
    private static let defaultObfuscatedHost = "aHR0cDovLzEwMy4yMzguMjM0LjIwNDo1Njc4"
    
    private static func resolveSecureHost() -> String {
        if let data = Data(base64Encoded: defaultObfuscatedHost),
           let decoded = String(data: data, encoding: .utf8) {
            return decoded
        }
        return "http://103.238.234.204:5678"
    }
    
    @Published public var serverURL: String = ""
    @Published public var isOnline: Bool = false
    @Published public var isStarting = true
    @Published public var startupError: String? = nil
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: String = ""
    @Published public var apiKey: String = ""
    @Published public var userRole: Int = 0
    @Published public var isHwidBlocked: Bool = false
    @Published public var lastError: String? = nil
    @Published public var isFreeCacheEnabled: Bool = true
    
    public var isVIP1: Bool {
        return userRole >= 1
    }
    
    public var isVIP2: Bool {
        return userRole >= 2
    }
    
    public var isVIP: Bool {
        return userRole >= 1
    }
    
    public var canMakeCache: Bool {
        return isVIP || isFreeCacheEnabled
    }
    
    // Hardware ID (Unique per device vendor)
    public var hwid: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "IOS-DEFAULT-HWID"
    }
    
    private var healthTimer: Timer?
    private var consecutiveFailures: Int = 0
    
    private init() {
        // Pure obfuscated server address, never exposed to user interface
        self.serverURL = APIService.resolveSecureHost()
        
        // Restore saved auth session
        self.currentUser = UserDefaults.standard.string(forKey: "regmod_user") ?? ""
        self.apiKey = UserDefaults.standard.string(forKey: "regmod_api_key") ?? ""
        self.userRole = UserDefaults.standard.integer(forKey: "regmod_user_role")
        self.isAuthenticated = !self.apiKey.isEmpty
        
        prepareSession()

        // Refresh connectivity and account permissions while the app is open.
        DispatchQueue.main.async {
            self.healthTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { [weak self] _ in
                guard let self = self, !self.isStarting else { return }
                self.checkHealth { [weak self] online in
                    if online, let strongSelf = self, strongSelf.isAuthenticated {
                        strongSelf.checkSession()
                    }
                }
            }
        }
    }
    
    public func prepareSession() {
        isStarting = true
        startupError = nil
        checkHealth { [weak self] online in
            guard let self = self else { return }
            guard online else {
                self.startupError = "Không thể kết nối máy chủ. Kiểm tra mạng rồi thử lại."
                self.isStarting = false
                return
            }
            self.verifyDeviceHWID { allowed in
                guard allowed else {
                    if !self.isHwidBlocked { self.startupError = "Chưa thể xác minh thiết bị. Vui lòng thử lại." }
                    self.isStarting = false
                    return
                }
                if self.isAuthenticated {
                    self.checkSession { valid, _ in
                        if !valid && self.isAuthenticated {
                            self.startupError = "Chưa thể xác minh phiên đăng nhập. Vui lòng thử lại."
                        }
                        self.isStarting = false
                    }
                } else {
                    self.isStarting = false
                }
            }
        }
    }

    // MARK: - Force Crash / Out When Server Offline
    public func triggerAppExit() {
        DispatchQueue.main.async {
            // Terminate application immediately
            exit(0)
        }
    }
    
    public func setServerURL(_ url: String) {
        var clean = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasSuffix("/") {
            clean.removeLast()
        }
        self.serverURL = clean
        self.checkHealth { _ in }
    }
    
    // MARK: - Report Security Violation (Auto Ban HWID on Server)
    public func reportSecurityViolation(reason: String) {
        guard let url = URL(string: "\(serverURL)/api/v1/security/report_violation") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 3.0
        let payload: [String: Any] = [
            "hwid": self.hwid,
            "reason": reason
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        URLSession.shared.dataTask(with: request).resume()
    }

    
    // MARK: - GATEKEEPER CHECK (Sync)
    public func canBuildMod() -> (allowed: Bool, reason: String) {
        if isHwidBlocked {
            return (false, "Thiết bị này (HWID) đã bị chặn bởi quản trị viên!")
        }
        if !isAuthenticated || apiKey.isEmpty {
            return (false, "Yêu cầu đăng nhập tài khoản để tạo bản mod!")
        }
        if !isOnline {
            return (false, "Không thể kết nối tới hệ thống máy chủ. Vui lòng kiểm tra mạng!")
        }
        return (true, "OK")
    }
    
    // MARK: - GATEKEEPER CHECK (Async with Live Network Verification)
    public func verifyGatekeeper(completion: @escaping (Bool, String) -> Void) {
        if isHwidBlocked {
            completion(false, "Thiết bị này (HWID) đã bị chặn bởi quản trị viên!")
            return
        }
        if !isAuthenticated || apiKey.isEmpty {
            completion(false, "Yêu cầu đăng nhập tài khoản để tạo bản mod!")
            return
        }
        
        // If already online, allow immediately
        if isOnline {
            completion(true, "OK")
            return
        }
        
        // Otherwise perform live health verification
        self.checkHealth { success in
            if success {
                completion(true, "OK")
            } else {
                completion(false, "Không thể kết nối tới hệ thống máy chủ. Vui lòng kiểm tra kết nối mạng!")
            }
        }
    }
    
    // MARK: - Health Check
    public func checkHealth(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(serverURL)/api/v1/health") else {
            DispatchQueue.main.async { 
                self.isOnline = false 
            }
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 3.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                    self.isOnline = true
                    self.consecutiveFailures = 0
                    if let d = data, let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
                       let freeEn = json["free_cache_enabled"] as? Bool {
                        self.isFreeCacheEnabled = freeEn
                    }
                    completion(true)
                } else {
                    self.isOnline = false
                    self.consecutiveFailures += 1
                    completion(false)
                }
            }
        }.resume()
    }
    
    // MARK: - HWID Verification
    public func verifyDeviceHWID(completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(serverURL)/api/verify_hwid") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 4.0
        
        let payload = ["hwid": self.hwid]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let isBlocked = json["is_blocked"] as? Bool else {
                    completion(false)
                    return
                }
                self.isHwidBlocked = isBlocked
                completion(!isBlocked)
            }
        }.resume()
    }
    
    // MARK: - Live Session Verification (Detects Account Deletion or Block -> Kicks App)
    public func checkSession(completion: ((Bool, String) -> Void)? = nil) {
        guard let url = URL(string: "\(serverURL)/api/check_session") else {
            completion?(false, "Địa chỉ máy chủ không hợp lệ")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 3.0
        
        let payload = [
            "username": self.currentUser,
            "api_key": self.apiKey,
            "hwid": self.hwid
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let http = response as? HTTPURLResponse, (http.statusCode == 401 || http.statusCode == 403) {
                    // Invalid sessions return to login; blocked devices show the lock screen.
                    let reason = (try? JSONSerialization.jsonObject(with: data ?? Data()) as? [String: Any])?["reason"] as? String ?? "BLOCKED"
                    if reason == "HWID_BLOCKED" {
                        self.isHwidBlocked = true
                    }
                    self.logout()
                    completion?(false, reason)
                    return
                }
                guard error == nil,
                      let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode),
                      let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let valid = json["valid"] as? Bool else {
                    completion?(false, "Không thể xác minh phiên")
                    return
                }
                if !valid {
                    let reason = json["reason"] as? String ?? "BLOCKED"
                    if reason == "HWID_BLOCKED" {
                        self.isHwidBlocked = true
                    }
                    self.logout()
                    completion?(false, reason)
                } else {
                    if let r = json["role"] as? Int {
                        self.userRole = r
                        UserDefaults.standard.set(r, forKey: "regmod_user_role")
                    }
                    if let freeEn = json["free_cache_enabled"] as? Bool {
                        self.isFreeCacheEnabled = freeEn
                    }
                    completion?(true, "OK")
                }
            }
        }.resume()
    }
    
    // MARK: - Login
    public func login(username: String, password: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let url = URL(string: "\(serverURL)/api/login") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(self.hwid, forHTTPHeaderField: "X-Device-HWID")
        
        let payload = [
            "username": username,
            "password": password,
            "hwid": self.hwid
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "Invalid Server Response", code: -2))) }
                return
            }
            
            DispatchQueue.main.async {
                if let success = json["success"] as? Bool, success,
                   let userData = json["data"] as? [String: Any] {
                    self.currentUser = userData["username"] as? String ?? username
                    self.apiKey = userData["api_key"] as? String ?? ""
                    let r = (userData["role"] as? Int) ?? 0
                    self.userRole = r
                    self.isAuthenticated = true
                    self.isHwidBlocked = false
                    
                    UserDefaults.standard.set(self.currentUser, forKey: "regmod_user")
                    UserDefaults.standard.set(self.apiKey, forKey: "regmod_api_key")
                    UserDefaults.standard.set(self.userRole, forKey: "regmod_user_role")
                    completion(.success(userData))
                } else {
                    let err = json["error"] as? String ?? "Đăng nhập thất bại"
                    completion(.failure(NSError(domain: err, code: -3)))
                }
            }
        }.resume()
    }
    
    // MARK: - Register
    public func register(username: String, password: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        guard let url = URL(string: "\(serverURL)/api/register") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(self.hwid, forHTTPHeaderField: "X-Device-HWID")
        
        let payload = [
            "username": username,
            "password": password,
            "hwid": self.hwid
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "Invalid Server Response", code: -2))) }
                return
            }
            
            DispatchQueue.main.async {
                if let success = json["success"] as? Bool, success,
                   let userData = json["data"] as? [String: Any] {
                    self.currentUser = userData["username"] as? String ?? username
                    self.apiKey = userData["api_key"] as? String ?? ""
                    let r = (userData["role"] as? Int) ?? 0
                    self.userRole = r
                    self.isAuthenticated = true
                    self.isHwidBlocked = false
                    
                    UserDefaults.standard.set(self.currentUser, forKey: "regmod_user")
                    UserDefaults.standard.set(self.apiKey, forKey: "regmod_api_key")
                    UserDefaults.standard.set(self.userRole, forKey: "regmod_user_role")
                    completion(.success(userData))
                } else {
                    let err = json["error"] as? String ?? "Đăng ký thất bại"
                    completion(.failure(NSError(domain: err, code: -3)))
                }
            }
        }.resume()
    }
    
    // MARK: - Logout
    public func logout() {
        self.currentUser = ""
        self.apiKey = ""
        self.userRole = 0
        self.isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "regmod_user")
        UserDefaults.standard.removeObject(forKey: "regmod_api_key")
        UserDefaults.standard.removeObject(forKey: "regmod_user_role")
    }
    
    // MARK: - Build Gun Shader via API (Zero Client-Side Logic)
    public func buildGunShader(
        version: String,
        mode: String = "mod",
        outlineRGB: [Float] = [255.0, 255.0, 0.0, 1.0],
        xrayRGB: [Float] = [255.0, 255.0, 255.0, 1.0],
        width: Float = 2.0,
        completion: @escaping (Result<(data: Data, filename: String), Error>) -> Void
    ) {
        let check = canBuildMod()
        if !check.allowed {
            completion(.failure(NSError(domain: check.reason, code: 403)))
            return
        }
        
        guard let url = URL(string: "\(serverURL)/api/v1/gun/build") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(self.apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(self.hwid, forHTTPHeaderField: "X-Device-HWID")
        request.timeoutInterval = 25.0
        
        let payload: [String: Any] = [
            "version": version,
            "mode": mode,
            "options": [
                "outline_color": outlineRGB,
                "xray_color": xrayRGB,
                "outline_width": width
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let self = self, let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "Lỗi phản hồi từ máy chủ", code: -2))) }
                return
            }
            
            if let success = json["success"] as? Bool, !success {
                let err = json["error"] as? String ?? "Tạo Shader thất bại"
                DispatchQueue.main.async { completion(.failure(NSError(domain: err, code: -3))) }
                return
            }
            
            let respFilename = json["filename"] as? String ?? "shaders_output"
            
            // Ultra-fast direct base64 data response
            if let b64 = json["data_b64"] as? String, let binData = Data(base64Encoded: b64) {
                DispatchQueue.main.async { completion(.success((binData, respFilename))) }
                return
            }
            
            // Resolve download URL with multi-layer fallback
            let downloadPath: String
            if let dlStr = json["download_url"] as? String, !dlStr.isEmpty {
                downloadPath = dlStr
            } else if let buildId = json["build_id"] as? String, !buildId.isEmpty {
                downloadPath = "/api/dv_download/\(buildId)"
            } else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "Missing Download URL", code: -4))) }
                return
            }
            
            let fullDLURL = downloadPath.hasPrefix("http") ? downloadPath : "\(self.serverURL)\(downloadPath)"
            guard let dlURL = URL(string: fullDLURL) else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "Invalid Download URL", code: -4))) }
                return
            }
            
            var dlReq = URLRequest(url: dlURL)
            dlReq.setValue(self.apiKey, forHTTPHeaderField: "X-API-Key")
            dlReq.setValue(self.hwid, forHTTPHeaderField: "X-Device-HWID")
            dlReq.timeoutInterval = 25.0
            
            URLSession.shared.dataTask(with: dlReq) { binData, _, dlError in
                DispatchQueue.main.async {
                    if let binData = binData {
                        completion(.success((binData, respFilename)))
                    } else {
                        completion(.failure(dlError ?? NSError(domain: "Lỗi tải file Shader", code: -5)))
                    }
                }
            }.resume()
        }.resume()
    }
    
    // MARK: - Build Hitbox Cache via API (Zero Client-Side Logic)
    public func buildHitboxCache(
        presetId: String? = nil,
        maleHeadRadius: Float? = nil,
        maleHeadCenterX: Float? = nil,
        maleHeadCenterY: Float? = nil,
        femaleHeadRadius: Float? = nil,
        femaleHeadCenterX: Float? = nil,
        femaleHeadCenterY: Float? = nil,
        maleSpineRadius: Float? = nil,
        maleSpineHeight: Float? = nil,
        femaleSpineRadius: Float? = nil,
        femaleSpineHeight: Float? = nil,
        customBaseData: Data? = nil,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        let check = canBuildMod()
        if !check.allowed {
            completion(.failure(NSError(domain: check.reason, code: 403)))
            return
        }
        
        if userRole < 1 && !isFreeCacheEnabled {
            completion(.failure(NSError(domain: "Tính năng tạo Cache miễn phí hiện đang tạm đóng bởi Quản trị viên! Vui lòng nâng cấp VIP hoặc liên hệ Admin.", code: 403)))
            return
        }
        
        guard let url = URL(string: "\(serverURL)/api/v1/hitbox/build") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(self.apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(self.hwid, forHTTPHeaderField: "X-Device-HWID")
        request.timeoutInterval = 25.0
        
        var payload: [String: Any] = [:]
        if let pid = presetId, !pid.isEmpty {
            payload["preset_id"] = pid
        }
        
        var params: [String: Any] = [:]
        var maleHead: [String: Any] = [:]
        if let r = maleHeadRadius { maleHead["radius"] = r }
        if let x = maleHeadCenterX { maleHead["center_x"] = x }
        if let y = maleHeadCenterY { maleHead["center_y"] = y }
        if !maleHead.isEmpty { params["male_head"] = maleHead }
        
        var femaleHead: [String: Any] = [:]
        if let r = femaleHeadRadius { femaleHead["radius"] = r }
        if let x = femaleHeadCenterX { femaleHead["center_x"] = x }
        if let y = femaleHeadCenterY { femaleHead["center_y"] = y }
        if !femaleHead.isEmpty { params["female_head"] = femaleHead }
        
        var maleSpine: [String: Any] = [:]
        if let r = maleSpineRadius { maleSpine["radius"] = r }
        if let h = maleSpineHeight { maleSpine["height"] = h }
        if !maleSpine.isEmpty { params["male_spine"] = maleSpine }
        
        var femaleSpine: [String: Any] = [:]
        if let r = femaleSpineRadius { femaleSpine["radius"] = r }
        if let h = femaleSpineHeight { femaleSpine["height"] = h }
        if !femaleSpine.isEmpty { params["female_spine"] = femaleSpine }
        
        if !params.isEmpty {
            payload["params"] = params
        }
        if let base = customBaseData, !base.isEmpty {
            payload["custom_base_base64"] = base.base64EncodedString()
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let self = self, let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "Lỗi phản hồi từ máy chủ", code: -2))) }
                return
            }
            
            if let success = json["success"] as? Bool, !success {
                let err = json["error"] as? String ?? "Tạo file Cache thất bại"
                DispatchQueue.main.async { completion(.failure(NSError(domain: err, code: -3))) }
                return
            }
            
            // Ultra-fast direct base64 data response
            if let b64 = json["data_b64"] as? String, let binData = Data(base64Encoded: b64) {
                DispatchQueue.main.async { completion(.success(binData)) }
                return
            }
            
            // Otherwise fallback to download_url
            let downloadPath: String
            if let dlStr = json["download_url"] as? String, !dlStr.isEmpty {
                downloadPath = dlStr
            } else if let buildId = json["build_id"] as? String, !buildId.isEmpty {
                downloadPath = "/api/download/\(buildId)"
            } else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "Thiếu URL tải file Cache", code: -4))) }
                return
            }
            
            let fullDLURL = downloadPath.hasPrefix("http") ? downloadPath : "\(self.serverURL)\(downloadPath)"
            guard let dlURL = URL(string: fullDLURL) else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "URL tải về không hợp lệ", code: -4))) }
                return
            }
            
            var dlReq = URLRequest(url: dlURL)
            dlReq.setValue(self.apiKey, forHTTPHeaderField: "X-API-Key")
            dlReq.setValue(self.hwid, forHTTPHeaderField: "X-Device-HWID")
            dlReq.timeoutInterval = 25.0
            
            URLSession.shared.dataTask(with: dlReq) { binData, _, dlError in
                DispatchQueue.main.async {
                    if let binData = binData {
                        completion(.success(binData))
                    } else {
                        completion(.failure(dlError ?? NSError(domain: "Lỗi tải file Cache", code: -5)))
                    }
                }
            }.resume()
        }.resume()
    }
    
    // MARK: - Upload Cache to VPS
    public func uploadCache(data: Data, filename: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let url = URL(string: "\(serverURL)/api/upload_base") else {
            completion(.failure(NSError(domain: "Invalid Server URL", code: -1)))
            return
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(self.apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(self.hwid, forHTTPHeaderField: "X-Device-HWID")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                DispatchQueue.main.async { completion(.success(true)) }
            } else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "Tải lên VPS thất bại", code: -2))) }
            }
        }.resume()
    }
    
    // MARK: - Build Avatar Mod via API (Zero Client-Side Logic)
    public func buildAvatarMod(
        presetId: String = "aimbot_head",
        targetBone: String = "bone_Head",
        parentHash: Int = -1541408846,
        scale: Double = 1.55,
        modMale: Bool = true,
        modFemale: Bool = true,
        modBigGun: Bool = false,
        gunScale: Double = 3.5,
        matchSize: Bool = true,
        patchMono: Bool = true,
        posX: Double? = nil,
        posY: Double? = nil,
        posZ: Double? = nil,
        rotX: Double? = nil,
        rotY: Double? = nil,
        rotZ: Double? = nil,
        rotW: Double? = nil,
        gameVersion: String = "fft",
        customFileBase64: String? = nil,
        completion: @escaping (Result<(data: Data, filename: String, changes: [String]), Error>) -> Void
    ) {
        let check = canBuildMod()
        if !check.allowed {
            completion(.failure(NSError(domain: check.reason, code: 403)))
            return
        }
        
        guard let url = URL(string: "\(serverURL)/api/v1/avatar/build") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(self.apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(self.hwid, forHTTPHeaderField: "X-Device-HWID")
        request.timeoutInterval = 30.0
        
        var payload: [String: Any] = [
            "game_version": gameVersion,
            "preset_id": presetId,
            "target_bone": targetBone,
            "parent_hash": parentHash,
            "scale": scale,
            "mod_male": modMale,
            "mod_female": modFemale,
            "mod_big_gun": modBigGun,
            "gun_scale": gunScale,
            "match_size": matchSize,
            "patch_monoscript": patchMono
        ]
        
        if let px = posX { payload["pos_x"] = px }
        if let py = posY { payload["pos_y"] = py }
        if let pz = posZ { payload["pos_z"] = pz }
        if let rx = rotX { payload["rot_x"] = rx }
        if let ry = rotY { payload["rot_y"] = ry }
        if let rz = rotZ { payload["rot_z"] = rz }
        if let rw = rotW { payload["rot_w"] = rw }
        
        if let customB64 = customFileBase64, !customB64.isEmpty {
            payload["custom_file_base64"] = customB64
        }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            guard let self = self, let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "Lỗi phản hồi từ máy chủ", code: -2))) }
                return
            }
            
            if let success = json["success"] as? Bool, !success {
                let err = json["error"] as? String ?? "Tạo Avatar Mod thất bại"
                DispatchQueue.main.async { completion(.failure(NSError(domain: err, code: -3))) }
                return
            }
            
            let respFilename = json["filename"] as? String ?? "assetindexer.U6Zffc4YIR3DslNj3cXvYGAqz58~3D"
            let changes = (json["changes"] as? [String]) ?? []
            
            // Direct base64 data response
            if let b64 = json["data_b64"] as? String, let binData = Data(base64Encoded: b64) {
                DispatchQueue.main.async { completion(.success((binData, respFilename, changes))) }
                return
            }
            
            // Fallback to download URL
            let downloadPath: String
            if let dlStr = json["download_url"] as? String, !dlStr.isEmpty {
                downloadPath = dlStr
            } else if let buildId = json["build_id"] as? String, !buildId.isEmpty {
                downloadPath = "/api/v1/avatar/download/\(buildId)"
            } else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "Thiếu URL tải Avatar Mod", code: -4))) }
                return
            }
            
            let fullDLURL = downloadPath.hasPrefix("http") ? downloadPath : "\(self.serverURL)\(downloadPath)"
            guard let dlURL = URL(string: fullDLURL) else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "URL tải về không hợp lệ", code: -4))) }
                return
            }
            
            var dlReq = URLRequest(url: dlURL)
            dlReq.setValue(self.apiKey, forHTTPHeaderField: "X-API-Key")
            dlReq.setValue(self.hwid, forHTTPHeaderField: "X-Device-HWID")
            dlReq.timeoutInterval = 30.0
            
            URLSession.shared.dataTask(with: dlReq) { binData, _, dlError in
                DispatchQueue.main.async {
                    if let binData = binData {
                        completion(.success((binData, respFilename, changes)))
                    } else {
                        completion(.failure(dlError ?? NSError(domain: "Lỗi tải file Avatar", code: -5)))
                    }
                }
            }.resume()
        }.resume()
    }
    
    // MARK: - Keyboard Dismiss Utility
    public static func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - View Modifier for Tap Outside to Hide Keyboard
public extension View {
    func hideKeyboardWhenTappedAround() -> some View {
        // Neutralized as safe pass-through to ensure bottom UITabBar touches and buttons are never swallowed
        self
    }
}

