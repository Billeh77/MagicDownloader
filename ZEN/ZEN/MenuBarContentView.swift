//
//  MenuBarContentView.swift
//  ZEN
//
//  Created by Layanne El Assaad on 2/28/25.
//

import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var downloadMonitor = DownloadMonitor()

    var body: some View {
        VStack {
            Text("ZEN Download Monitor")
                .font(.headline)
                .padding()

            if let latestFile = downloadMonitor.latestFile {
                Text("Latest: \(latestFile.lastPathComponent)")
                    .font(.subheadline)
                    .padding(.bottom, 5)
            } else {
                Text("No recent downloads detected")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Button("Open Downloads Folder") {
                if let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
                    NSWorkspace.shared.open(downloadsURL)
                }
            }

            Divider()

            Button("Quit ZEN") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
    }
}
