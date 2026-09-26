import Foundation
import UIKit
import Darwin
import MachO

public final class AntiHexProSecurity {
    public static let shared = AntiHexProSecurity()
    
    private var sentinelTimer: DispatchSourceTimer?
    private let securityQueue = DispatchQueue(label: "com.flork.security.sentinel", qos: .background)
    private var isProtectionActive: Bool = false
    
    private init() {}
    
    // MARK: - Master Activation (Non-blocking Asynchronous)
    public func activateAllProtections() {
        guard !isProtectionActive else { return }
        isProtectionActive = true
        
        // Purge any cracker remnant keys left from past testing of cracked IPAs
        UserDefaults.standard.removeObject(forKey: "regmod_is_authenticated")
        UserDefaults.standard.removeObject(forKey: "auth_blocked_hwid")
        UserDefaults.standard.synchronize()
        
        // Initial scan after 1.0s to let SwiftUI window attach smoothly, zero black screen or freeze
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.performComprehensiveSecurityScan()
            self.startContinuousSentinel()
        }
    }
    
    // MARK: - Master Comprehensive Scan
    public func performComprehensiveSecurityScan() {
        scanDyldEnvironment()
        scanLoadedImages()
        scanBundleFrameworksDirectory()
        scanObjectiveCRuntime()
        validateBinaryIntegrity()
    }
    
    // MARK: - 1. Environment Check
    public func scanDyldEnvironment() {
        if let val = getenv("DYLD_INSERT_LIBRARIES") {
            let strVal = String(cString: val).lowercased()
            if strVal.contains("regmod") || strVal.contains("_ahlpr") || strVal.contains("frida") || strVal.contains("cycript") {
                triggerSecurityViolation(reason: "Phát hiện chèn dylib độc hại qua DYLD_INSERT_LIBRARIES: \(strVal)")
                return
            }
        }
    }
    
    // MARK: - 2. Loaded Dylib Inspection & Injected Bundle Dylibs
    public func scanLoadedImages() {
        let imageCount = _dyld_image_count()
        
        for i in 0..<imageCount {
            guard let cName = _dyld_get_image_name(i) else { continue }
            let imagePath = String(cString: cName).lowercased()
            
            // Check specific cracker signatures
            if imagePath.contains("regmod.dylib") || 
               imagePath.contains("_ahlpr") || 
               imagePath.contains("regmod_inject") || 
               imagePath.contains("frida-agent") || 
               imagePath.contains("cycript") {
                triggerSecurityViolation(reason: "Phát hiện nạp dylib can thiệp trái phép: \(imagePath)")
                return
            }
            
            // Check if regmod is loaded from Frameworks
            if imagePath.contains("/frameworks/regmod") {
                triggerSecurityViolation(reason: "Phát hiện dylib regmod trong Frameworks: \(imagePath)")
                return
            }
        }
    }
    
    // MARK: - 3. Bundle File System Scan for Injected Dylib Files
    public func scanBundleFrameworksDirectory() {
        let bundlePath = Bundle.main.bundlePath
        let frameworksPath = (bundlePath as NSString).appendingPathComponent("Frameworks")
        let regmodFile = (frameworksPath as NSString).appendingPathComponent("regmod.dylib")
        
        if FileManager.default.fileExists(atPath: regmodFile) {
            triggerSecurityViolation(reason: "Phát hiện file regmod.dylib trong thư mục Frameworks của App!")
            return
        }
    }
    
    // MARK: - 4. Objective-C Runtime Inspection
    public func scanObjectiveCRuntime() {
        // Cracker helper class created by regmod.dylib
        if NSClassFromString("_AHlpr") != nil {
            triggerSecurityViolation(reason: "Phát hiện runtime class can thiệp của regmod.dylib: _AHlpr")
            return
        }
    }
    
    // MARK: - 5. Mach-O Integrity Engine
    public func validateBinaryIntegrity() {
        guard let header = _dyld_get_image_header(0) else { return }
        let magic = header.pointee.magic
        if magic != MH_MAGIC_64 && magic != MH_CIGAM_64 {
            triggerSecurityViolation(reason: "Sai cấu trúc nhị phân thực thi")
        }
    }
    
    // MARK: - 6. Continuous Background Sentinel (Every 2.5s)
    private func startContinuousSentinel() {
        sentinelTimer = DispatchSource.makeTimerSource(queue: securityQueue)
        sentinelTimer?.schedule(deadline: .now() + 2.5, repeating: 2.5)
        sentinelTimer?.setEventHandler { [weak self] in
            guard let self = self else { return }
            self.performComprehensiveSecurityScan()
        }
        sentinelTimer?.resume()
    }
    
    // MARK: - Security Violation Handler (Report, Ban HWID & Terminate)
    public func triggerSecurityViolation(reason: String) {
        print("[CRITICAL SECURITY VIOLATION] \(reason)")
        
        // 1. Report to server to auto-ban this HWID
        APIService.shared.reportSecurityViolation(reason: reason)
        
        // 2. Wipe local authentication session
        UserDefaults.standard.removeObject(forKey: "regmod_user")
        UserDefaults.standard.removeObject(forKey: "regmod_api_key")
        UserDefaults.standard.removeObject(forKey: "regmod_user_role")
        UserDefaults.standard.synchronize()
        
        // 3. Immediately terminate application to prevent dylib execution
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            kill(getpid(), SIGKILL)
            exit(177)
        }
    }
    
    // MARK: - XOR String Deobfuscator
    public static func xorDecrypt(_ bytes: [UInt8], key: UInt8 = 0x5E) -> String {
        let decoded = bytes.map { $0 ^ key }
        return String(bytes: decoded, encoding: .utf8) ?? ""
    }
}
