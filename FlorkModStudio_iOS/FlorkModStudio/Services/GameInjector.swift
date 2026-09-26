import Foundation
import UIKit
import SwiftUI

public final class GameInjector {
    public static let shared = GameInjector()
    
    private init() {}
    
    // MARK: - Save File to Temporary URL for Sharing or File Picker
    public func saveTempFile(data: Data, filename: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Lỗi lưu file tạm: \(error)")
            return nil
        }
    }
    
    // MARK: - Share Sheet (Save to Files App / AirDrop)
    public func presentShareSheet(fileURL: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootVC.view
            popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        rootVC.present(activityVC, animated: true)
    }
    
    // MARK: - TrollStore / Jailbreak Direct Injec    // MARK: - TrollStore / Jailbreak Direct Injection (Recursive & Multi-Path Coverage)
    public func directInjectToGame(version: GameVersion, filename: String, data: Data) -> (success: Bool, message: String) {
        // Paths for TrollStore / Jailbreak
        let containerBase = "/var/mobile/Containers/Data/Application"
        guard FileManager.default.fileExists(atPath: containerBase) else {
            return (false, "Không có quyền truy cập root container. Vui lòng bấm 'Lưu Vào Tệp' và chép thủ công bằng ứng dụng Tệp (Files).")
        }
        
        let targetBundle = version.bundleIdentifier
        do {
            let appDirs = try FileManager.default.contentsOfDirectory(atPath: containerBase)
            for dir in appDirs {
                let metadataPath = "\(containerBase)/\(dir)/.com.apple.mobile_container_manager.metadata.plist"
                if FileManager.default.fileExists(atPath: metadataPath),
                   let dict = NSDictionary(contentsOfFile: metadataPath) as? [String: Any],
                   let bundleId = dict["MCMMetadataIdentifier"] as? String,
                   bundleId == targetBundle {
                    
                    let rootDir = "\(containerBase)/\(dir)"
                    let documentsPath = "\(rootDir)/Documents"
                    var injectedCount = 0
                    
                    // 1. Recursive Scan: Replace EVERY existing instance in Documents AND Library
                    for baseFolder in ["\(rootDir)/Documents", "\(rootDir)/Library"] {
                        if let enumerator = FileManager.default.enumerator(atPath: baseFolder) {
                            for case let subPath as String in enumerator {
                                let lastComponent = (subPath as NSString).lastPathComponent
                                let isTarget = (lastComponent == filename) ||
                                               (filename.hasPrefix("cache_res") && lastComponent.hasPrefix("cache_res")) ||
                                               (filename.hasPrefix("assetindexer") && lastComponent.hasPrefix("assetindexer"))
                                if isTarget {
                                    let fullPath = "\(baseFolder)/\(subPath)"
                                    let backupPath = "\(fullPath).bak"
                                    if !FileManager.default.fileExists(atPath: backupPath) {
                                        try? FileManager.default.copyItem(atPath: fullPath, toPath: backupPath)
                                    }
                                    try? data.write(to: URL(fileURLWithPath: fullPath))
                                    injectedCount += 1
                                }
                            }
                        }
                    }
                    
                    // 2. Multi-Path Placement to ensure game loads regardless of read location
                    var targetPaths: [String] = [
                        "\(documentsPath)/\(filename)",
                        "\(documentsPath)/content/Temp/res/\(filename)",
                        "\(documentsPath)/content/Temp/res/cache_res.CfnFf59sr1SbsqQ6JqTKsEusjKs~3D",
                        "\(documentsPath)/content/Temp/res/cache_res.GkLlYqzsX4AtTdE55sDMRh9sJOI~3D"
                    ]
                    
                    if filename.contains("assetindexer") {
                        targetPaths.append("\(documentsPath)/contentcache/Compulsory/ios/gameassetbundles/\(filename)")
                        targetPaths.append("\(documentsPath)/contentcache/Compulsory/gameassetbundles/\(filename)")
                        targetPaths.append("\(documentsPath)/contentcache/Compulsory/ios/gameassetbundles/assetindexer.U6Zffc4YIR3DslNj3cXvYGAqz58~3D")
                        targetPaths.append("\(documentsPath)/contentcache/Compulsory/ios/gameassetbundles/assetindexer.H5ak1JM1Eck~2FxRcJrEp~2FMzeuqmY~3D")
                    }
                    
                    for p in targetPaths {
                        let folderURL = URL(fileURLWithPath: p).deletingLastPathComponent()
                        try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
                        
                        let backupPath = "\(p).bak"
                        if !FileManager.default.fileExists(atPath: backupPath) && FileManager.default.fileExists(atPath: p) {
                            try? FileManager.default.copyItem(atPath: p, toPath: backupPath)
                        }
                        try? data.write(to: URL(fileURLWithPath: p))
                        injectedCount += 1
                    }
                    
                    return (true, "Đã inject đè thành công \(injectedCount) vị trí trong \(version.displayName) (Documents, content/Temp/res & gameassetbundles)!")
                }
            }
        } catch {
            return (false, "Lỗi khi quét thư mục game: \(error.localizedDescription)")
        }
        
        return (false, "Không tìm thấy thư mục cài đặt của \(targetBundle). Hãy dùng tính năng 'Lưu Vào Tệp'.")
    }
    
    // MARK: - Auto-Extract Cache from Game on Device
    public func readCacheFromGame(version: GameVersion, filename: String = "cache_res.GkLlYqzsX4AtTdE55sDMRh9sJOI~3D") -> (data: Data?, actualFilename: String?, message: String) {
        let containerBase = "/var/mobile/Containers/Data/Application"
        guard FileManager.default.fileExists(atPath: containerBase) else {
            return (nil, nil, "Thiết bị không có quyền truy cập root container trực tiếp (yêu cầu TrollStore hoặc Jailbreak).")
        }
        
        let targetBundle = version.bundleIdentifier
        do {
            let appDirs = try FileManager.default.contentsOfDirectory(atPath: containerBase)
            for dir in appDirs {
                let metadataPath = "\(containerBase)/\(dir)/.com.apple.mobile_container_manager.metadata.plist"
                if FileManager.default.fileExists(atPath: metadataPath),
                   let dict = NSDictionary(contentsOfFile: metadataPath) as? [String: Any],
                   let bundleId = dict["MCMMetadataIdentifier"] as? String,
                   bundleId == targetBundle {
                    
                    let documentsPath = "\(containerBase)/\(dir)/Documents"
                    
                    // 1. Check known direct paths
                    let checkPaths = [
                        "\(documentsPath)/content/Temp/res/\(filename)",
                        "\(documentsPath)/\(filename)"
                    ]
                    for cp in checkPaths {
                        if FileManager.default.fileExists(atPath: cp),
                           let fileData = try? Data(contentsOf: URL(fileURLWithPath: cp)) {
                            return (fileData, filename, "Đã nạp thành công '\(filename)' từ \(version.displayName) (\(fileData.count) bytes)!")
                        }
                    }
                    
                    // 2. Recursive scan for any cache_res file in Documents
                    if let enumerator = FileManager.default.enumerator(atPath: documentsPath) {
                        for case let subPath as String in enumerator {
                            let lastComponent = (subPath as NSString).lastPathComponent
                            if lastComponent.hasPrefix("cache_res") {
                                let fPath = "\(documentsPath)/\(subPath)"
                                if let fData = try? Data(contentsOf: URL(fileURLWithPath: fPath)) {
                                    return (fData, lastComponent, "Đã tìm thấy '\(lastComponent)' (\(fData.count) bytes) từ \(version.displayName)!")
                                }
                            }
                        }
                    }
                    
                    return (nil, nil, "Tìm thấy game \(version.displayName) nhưng chưa có tệp cache trong thư mục Documents.")
                }
            }
        } catch {
            return (nil, nil, "Lỗi khi quét thư mục game: \(error.localizedDescription)")
        }
        
        return (nil, nil, "Không tìm thấy thư mục cài đặt của \(version.displayName) trên máy.")
    }
    
    // MARK: - Inject Cache File
    public func injectCacheFile(data: Data, filename: String, version: GameVersion = .fft, completion: @escaping (Bool, String) -> Void) {
        guard let fileURL = saveTempFile(data: data, filename: filename) else {
            completion(false, "Không thể tạo file tạm.")
            return
        }
        
        let result = directInjectToGame(version: version, filename: filename, data: data)
        if result.success {
            completion(true, result.message)
        } else {
            DispatchQueue.main.async {
                self.presentShareSheet(fileURL: fileURL)
                completion(true, "Đã xuất file \(filename) thành công! Bạn có thể lưu vào Tệp hoặc chia sẻ.")
            }
        }
    }
    
    // MARK: - Inject Shader File
    public func injectShaderFile(data: Data, filename: String, version: GameVersion, completion: @escaping (Bool, String) -> Void) {
        guard let fileURL = saveTempFile(data: data, filename: filename) else {
            completion(false, "Không thể tạo file shader tạm.")
            return
        }
        
        let result = directInjectToGame(version: version, filename: filename, data: data)
        if result.success {
            completion(true, result.message)
        } else {
            DispatchQueue.main.async {
                self.presentShareSheet(fileURL: fileURL)
                completion(true, "Đã xuất shader \(filename) thành công! Bạn có thể lưu vào Tệp hoặc chia sẻ.")
            }
        }
    }
}
