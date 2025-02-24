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

        // ✅ Retrieve stored bookmark
        if let bookmarkData = UserDefaults.standard.data(forKey: folderKey) {
            do {
                var isStale = false
                let restoredURL = try URL(resolvingBookmarkData: bookmarkData,
                                          options: .withSecurityScope,
                                          relativeTo: nil,
                                          bookmarkDataIsStale: &isStale)

                if isStale {
                    print("Bookmark data is stale. Requesting permission again.")
                    requestFolderAccess(for: selectedFolder)
                    return
                }

                // ✅ Start security-scoped access
                if restoredURL.startAccessingSecurityScopedResource() {
                    refreshFiles()
                } else {
                    print("Failed to access security-scoped resource.")
                }
            } catch {
                print("Error resolving security-scoped bookmark: \(error)")
                requestFolderAccess(for: selectedFolder) // Fallback to manual selection
            }
        } else {
            requestFolderAccess(for: selectedFolder) // First-time request
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
                do {
                    // ✅ Create a security-scoped bookmark
                    let bookmarkData = try selectedURL.bookmarkData(options: .withSecurityScope,
                                                                    includingResourceValuesForKeys: nil,
                                                                    relativeTo: nil)

                    // ✅ Store the bookmark in UserDefaults
                    UserDefaults.standard.set(bookmarkData, forKey: folder.userDefaultsKey)
                    
                    // ✅ Refresh the file list immediately after permission is granted
                    refreshFiles()
                } catch {
                    print("Error creating security-scoped bookmark: \(error)")
                }
            }
        }
    }


    
    /// ✅ Refreshes the file list based on the selected folder
    /// ✅ Sorts files by creation date (most recent first)
    private func refreshFiles() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: selectedFolder.userDefaultsKey) else {
            print("No stored bookmark for \(selectedFolder.rawValue), requesting access...")
            requestFolderAccess(for: selectedFolder)
            return
        }

        do {
            var isStale = false
            let folderURL = try URL(resolvingBookmarkData: bookmarkData,
                                    options: .withSecurityScope,
                                    relativeTo: nil,
                                    bookmarkDataIsStale: &isStale)

            print("Resolved folder URL: \(folderURL.path)")

            if isStale {
                print("Bookmark data is stale. Requesting permission again.")
                requestFolderAccess(for: selectedFolder)
                return
            }

            if folderURL.startAccessingSecurityScopedResource() {
                defer { folderURL.stopAccessingSecurityScopedResource() }

                let fileURLs = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.creationDateKey], options: [])

                print("Files found: \(fileURLs.count)")
                for file in fileURLs {
                    print(" - \(file.lastPathComponent)")
                }

                self.files = fileURLs.sorted {
                    let date1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    let date2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    return date1 > date2
                }
            } else {
                print("Failed to access security-scoped resource.")
            }
        } catch {
            print("Error accessing \(selectedFolder.rawValue) folder: \(error)")
        }
    }

}

#Preview {
    ContentView()
}

