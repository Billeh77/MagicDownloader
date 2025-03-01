import SwiftUI
import AppKit

@main
struct ZENApp: App {
    @StateObject private var downloadMonitor = DownloadMonitor()
    @StateObject private var menuBarManager = MenuBarManager() // ✅ Ensure proper initialization

    init() {
        print("🚀 ZENApp Initialized")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(downloadMonitor)
                .environmentObject(menuBarManager) // ✅ Inject MenuBarManager
        }

        
    }
}
