import SwiftUI
import AppKit



class AppDelegate: NSObject, NSApplicationDelegate {

    var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
       

    }

    /// Call this when user clicks “Open in ZEN”
    func openZENMainWindow(with fileURL: URL?) {
        if mainWindow == nil {
            let view = ContentView(selectedInitialFile: fileURL)
            let hostingController = NSHostingController(rootView: view)

            mainWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
                styleMask: [.titled, .closable, .resizable, .miniaturizable],
                backing: .buffered, defer: false
            )
            mainWindow?.contentViewController = hostingController
            mainWindow?.title = "ZEN Main Window"
            mainWindow?.makeKeyAndOrderFront(nil)
        } else {
            mainWindow?.makeKeyAndOrderFront(nil)
            if let fileURL = fileURL,
               let contentVC = mainWindow?.contentViewController as? NSHostingController<ContentView> {
                contentVC.rootView.handleIncomingFile(fileURL)
            }
        }

        NSApp.activate(ignoringOtherApps: true)
    }
}


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
