import SwiftUI
import AppKit

class MenuBarManager: ObservableObject {
    @Published var latestFile: URL? = nil
    private var statusItem: NSStatusItem
    private var popover: NSPopover

    init() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()
        self.popover.behavior = .transient
        self.popover.contentViewController = NSHostingController(rootView: MenuBarView().environmentObject(self))

        setupMenuBar()
    }

    private func setupMenuBar() {
        if let button = self.statusItem.button {
            button.image = NSImage(systemSymbolName: "arrow.down.doc", accessibilityDescription: "ZEN Monitor")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }

    func showMenu(for file: URL) {
        DispatchQueue.main.async {
            self.latestFile = file
            if let button = self.statusItem.button {
                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true) // ✅ Bring app forward
            } else {
                print("❌ Error: statusItem button not found")
            }
        }
    }

    func hideMenu() {
        popover.performClose(nil)
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            hideMenu()
        } else {
            showMenu(for: latestFile ?? URL(fileURLWithPath: ""))
        }
    }
}
