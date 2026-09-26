import Foundation

public enum GameVersion: String, CaseIterable, Identifiable {
    case fft = "fft"
    case ffm = "ffm"
    
    public var id: String { self.rawValue }
    
    public var displayName: String {
        switch self {
        case .fft: return "⚡ Free Fire Thường (FFT)"
        case .ffm: return "🔥 Free Fire MAX (FFM)"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .fft: return "Bản game tiêu chuẩn, nhẹ, mượt mà"
        case .ffm: return "Bản đồ họa cao cấp MAX Graphics"
        }
    }
    
    public var bundleIdentifier: String {
        switch self {
        case .fft: return "com.dts.freefireth"
        case .ffm: return "com.dts.freefiremax"
        }
    }
}
