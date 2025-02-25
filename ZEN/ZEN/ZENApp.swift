//
//  ZENApp.swift
//  ZEN
//
//  Created by Emile Billeh on 23/02/2025.
//

import SwiftUI

@main
struct ZENApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        installLaunchAgent() // ✅ Install the Launch Agent at startup
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }

    /// ✅ Copies the Launch Agent file into the user's `LaunchAgents` folder
    private func installLaunchAgent() {
        let fileManager = FileManager.default
        let launchAgentPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.MagicDownloader.zen.plist")

        print("🔍 Checking Launch Agent at: \(launchAgentPath.path)")

        if fileManager.fileExists(atPath: launchAgentPath.path) {
            print("✅ Launch Agent already installed at \(launchAgentPath.path)")

            // ✅ Try manually starting the agent for debugging
            let task = Process()
            task.launchPath = "/bin/launchctl"
            task.arguments = ["bootstrap", "gui/\(getuid())", launchAgentPath.path]

            do {
                try task.run()
                print("🚀 Successfully started launch agent.")
            } catch {
                print("❌ Failed to start launch agent: \(error)")
            }

            return
        }

        guard let embeddedLaunchAgent = Bundle.main.url(forResource: "com.MagicDownloader.zen", withExtension: "plist") else {
            print("❌ Could not find Launch Agent in bundle. Check 'Copy Bundle Resources' and file name.")
            return
        }

        print("📂 Found embedded launch agent: \(embeddedLaunchAgent.path)")

        do {
            try fileManager.copyItem(at: embeddedLaunchAgent, to: launchAgentPath)
            print("🚀 Launch Agent copied successfully to \(launchAgentPath.path)")

            // ✅ Load the agent
            let task = Process()
            task.launchPath = "/bin/launchctl"
            task.arguments = ["load", launchAgentPath.path]
            task.launch()

            print("✅ Launch Agent should now be loaded.")
        } catch {
            print("❌ Failed to install Launch Agent: \(error)")
        }
    }

}
