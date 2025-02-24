//
//  ContentView.swift
//  ZEN
//
//  Created by Emile Billeh on 23/02/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var files: [URL] = []
    @State private var selectedFolder: FolderType = .downloads

    enum FolderType: String, CaseIterable, Identifiable {
        case downloads = "Downloads"
        case documents = "Documents"
        case desktop = "Desktop"

        var id: String { self.rawValue }

        var directoryURL: URL? {
            switch self {
            case .downloads:
                return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            case .documents:
                return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            case .desktop:
                return FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
            }
        }

        var userDefaultsKey: String {
            "accessedFolder_\(self.rawValue)"
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // ✅ Drop-down menu to select Downloads, Documents, or Desktop
                Picker("Select Folder", selection: $selectedFolder) {
                    ForEach(FolderType.allCases) { folder in
                        Text(folder.rawValue).tag(folder)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .onChange(of: selectedFolder) {
                    DispatchQueue.main.async {
                        checkAndRequestFolderAccess() // ✅ Trigger permission check and refresh on selection change
                    }
                }

                List(files, id: \.self) { file in
                    NavigationLink(destination: FileInfoAndMovingView(fileURL: file)) {
                        Text(file.lastPathComponent)
                    }
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
    
    /// ✅ Checks if the user has granted access to the selected folder, otherwise requests it
    private func checkAndRequestFolderAccess() {
        let folderKey = selectedFolder.userDefaultsKey
        if UserDefaults.standard.string(forKey: folderKey) == nil {
            requestFolderAccess(for: selectedFolder)
        } else {
            refreshFiles()
        }
    }

    /// ✅ Requests access to the selected folder (Downloads, Documents, or Desktop)
    private func requestFolderAccess(for folder: FolderType) {
        DispatchQueue.main.async {
            let openPanel = NSOpenPanel()
            openPanel.message = "Please grant access to your \(folder.rawValue) folder"
            openPanel.prompt = "Allow"
            openPanel.canChooseFiles = false
            openPanel.canChooseDirectories = true
            openPanel.allowsMultipleSelection = false
            openPanel.directoryURL = folder.directoryURL

            if openPanel.runModal() == .OK, let selectedURL = openPanel.url {
                UserDefaults.standard.set(selectedURL.path, forKey: folder.userDefaultsKey)
                refreshFiles()
            }
        }
    }
    
    /// ✅ Refreshes the file list based on the selected folder
    /// ✅ Sorts files by creation date (most recent first)
    private func refreshFiles() {
        guard let path = UserDefaults.standard.string(forKey: selectedFolder.userDefaultsKey) else { return }
        let folderURL = URL(fileURLWithPath: path)

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.creationDateKey], options: [])

            // ✅ Sorting files by creation date (newest first)
            let sortedFiles = fileURLs.sorted {
                let date1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 > date2
            }

            self.files = sortedFiles
        } catch {
            print("Error accessing \(selectedFolder.rawValue) folder: \(error)")
        }
    }
}

#Preview {
    ContentView()
}

