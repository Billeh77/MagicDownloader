import SwiftUI
import AppKit

class MenuBarController {
    static let shared = MenuBarController()

    private var popover: NSPopover
    private var statusItem: NSStatusItem!

    private init() {
        self.popover = NSPopover()
        self.popover.behavior = .transient // Auto-hide when clicking outside
        self.setupMenuBar()
    }

    private func setupMenuBar() {
        DispatchQueue.main.async {
            self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            if let button = self.statusItem.button {
                button.image = NSImage(systemSymbolName: "arrow.down.doc", accessibilityDescription: "Downloads Monitor")
                button.action = #selector(self.togglePopover(_:))
                button.target = self
            }
        }
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            popover.performClose(sender)
        } else if let button = statusItem?.button {
            self.showPopover()
        }
    }

    /// ✅ **Ensures menu pops up immediately**
    func showPopover() {
        DispatchQueue.main.async {
            if let button = self.statusItem?.button {
                self.setupPopoverContent()
                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

                // ✅ Bring the app forward to make the menu bar visible
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
    }

    private func setupPopoverContent() {
        if popover.contentViewController == nil {
            let menuView = MenuBarView()
            popover.contentViewController = NSHostingController(rootView: menuView)
        }
    }
}
