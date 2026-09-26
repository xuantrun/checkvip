import SwiftUI

@main
struct FlorkModStudioApp: App {
    init() {
        // Activate Anti-Dylib, Anti-Hex, Anti-Debug and Runtime Sentinel immediately at app launch
        AntiHexProSecurity.shared.activateAllProtections()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
