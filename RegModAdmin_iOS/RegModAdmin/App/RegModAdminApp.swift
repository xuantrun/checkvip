import SwiftUI

@main
struct RegModAdminApp: App {
    @StateObject private var api = AdminAPIService.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if api.isAuthenticated {
                    AdminDashboardView()
                } else {
                    AdminLoginView()
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
