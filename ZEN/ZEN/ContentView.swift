//
//  ContentView.swift
//  ZEN
//
//  Created by Emile Billeh on 23/02/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var files: [URL] = []
    
    var body: some View {
        NavigationView {
            List(files, id: \.self) { file in
                NavigationLink(destination: Text(file.lastPathComponent)) {
                    Text(file.lastPathComponent)
                }
            }
            .toolbar {
                ToolbarItem {
                    Button(action: refreshFiles) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    checkAndRequestFolderAccess()
                }
            }
            
            Text("Select a file")
        }
    }
    
    /// Checks if the user has granted access to Downloads, otherwise requests it
    private func checkAndRequestFolderAccess() {
        if UserDefaults.standard.string(forKey: "downloadsFolder") == nil {
            requestFolderAccess()
        } else {
            refreshFiles()
        }
    }

    /// Asks the user for access to the Downloads folder using NSOpenPanel
    private func requestFolderAccess() {
        DispatchQueue.main.async {
            let openPanel = NSOpenPanel()
            openPanel.message = "Please grant access to your Downloads folder"
            openPanel.prompt = "Allow"
            openPanel.canChooseFiles = false
            openPanel.canChooseDirectories = true
            openPanel.allowsMultipleSelection = false
            openPanel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            
            if openPanel.runModal() == .OK, let selectedURL = openPanel.url {
                UserDefaults.standard.set(selectedURL.path, forKey: "downloadsFolder")
                refreshFiles()
            }
        }
    }
    
    /// Reads and lists the files from the Downloads folder
    private func refreshFiles() {
        guard let path = UserDefaults.standard.string(forKey: "downloadsFolder") else { return }
        let downloadsURL = URL(fileURLWithPath: path)
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: downloadsURL, includingPropertiesForKeys: nil)
            self.files = fileURLs.filter { !$0.hasDirectoryPath } // Show only files, not folders
        } catch {
            print("Error accessing Downloads folder: \(error)")
        }
    }
}

#Preview {
    ContentView()
}

