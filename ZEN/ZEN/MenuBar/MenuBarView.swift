import SwiftUI
import AppKit

struct MenuBarView: View {
    @EnvironmentObject var menuBarManager: MenuBarManager

    var body: some View {
        VStack {
            Text("ZEN Download Monitor")
                .font(.headline)
                .padding()

            if let latestFile = menuBarManager.latestFile { // ✅ No more red underline
                VStack(spacing: 10) {
                    Text("New File Downloaded!")
                        .font(.subheadline)
                        .bold()
                    Text(latestFile.lastPathComponent)
                        .font(.footnote)
                        .foregroundColor(.gray)

                    HStack {
                        Button("Open File") {
                            openFile(latestFile)
                        }
                        .buttonStyle(.bordered)

                        Button("Open in ZEN") {
                            openInZen(latestFile)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.bottom, 10)
            } else {
                Text("No recent downloads detected")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Divider()

            Button("Quit ZEN") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .onReceive(NotificationCenter.default.publisher(for: .newDownloadDetected)) { notification in
            if let fileURL = notification.object as? URL {
                menuBarManager.showMenu(for: fileURL)
            }
        }
    }

    private func openFile(_ file: URL) {
        NSWorkspace.shared.open(file)
    }

    private func openInZen(_ file: URL) {
        if let appDelegate = NSApp.delegate as? AppDelegate {
            appDelegate.openZENMainWindow(with: file)
        } else {
            print("❌ Could not get AppDelegate")
        }
    }

}
