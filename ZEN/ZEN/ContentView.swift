//
//  ContentView.swift
//  ZEN
//
//  Created by Emile Billeh on 23/02/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var files: [URL] = []
    @State private var selectedFile: URL? // ✅ Stores the most recent file
    @State private var selectedFolder: FolderType = .downloads
    private let fileMonitor = FileMonitor() // ✅ File monitor to detect new files

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
                        checkAndRequestFolderAccess()
                        startMonitoringFolder()
                    }
                }

                List(files, id: \.self) { file in
                    NavigationLink(destination: ItemInfoAndMovingView(fileURL: file),
                                   tag: file,
                                   selection: $selectedFile) { // ✅ Auto-select recent file
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
                    startMonitoringFolder()
                }
            }

            Text("Select a file")
        }
    }
    
    /// ✅ Checks if the user has granted access to the selected folder, otherwise requests it
    private func checkAndRequestFolderAccess() {
        let folderKey = selectedFolder.userDefaultsKey

        if let bookmarkData = UserDefaults.standard.data(forKey: folderKey) {
            do {
                var isStale = false
                let restoredURL = try URL(resolvingBookmarkData: bookmarkData,
                                          options: .withSecurityScope,
                                          relativeTo: nil,
                                          bookmarkDataIsStale: &isStale)

                if isStale {
                    requestFolderAccess(for: selectedFolder)
                    return
                }

                if restoredURL.startAccessingSecurityScopedResource() {
                    refreshFiles()
                } else {
                    print("Failed to access security-scoped resource.")
                }
            } catch {
                requestFolderAccess(for: selectedFolder)
            }
        } else {
            requestFolderAccess(for: selectedFolder)
        }
    }

    /// ✅ Requests access to the selected folder
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
                    let bookmarkData = try selectedURL.bookmarkData(options: .withSecurityScope,
                                                                    includingResourceValuesForKeys: nil,
                                                                    relativeTo: nil)
                    UserDefaults.standard.set(bookmarkData, forKey: folder.userDefaultsKey)
                    refreshFiles()
                } catch {
                    print("Error creating security-scoped bookmark: \(error)")
                }
            }
        }
    }

    /// ✅ Refreshes the file list and auto-selects the most recent file
    private func refreshFiles() {
        guard let bookmarkData = UserDefaults.standard.data(forKey: selectedFolder.userDefaultsKey) else {
            requestFolderAccess(for: selectedFolder)
            return
        }

        do {
            var isStale = false
            let folderURL = try URL(resolvingBookmarkData: bookmarkData,
                                    options: .withSecurityScope,
                                    relativeTo: nil,
                                    bookmarkDataIsStale: &isStale)

            if isStale {
                requestFolderAccess(for: selectedFolder)
                return
            }

            if folderURL.startAccessingSecurityScopedResource() {
                defer { folderURL.stopAccessingSecurityScopedResource() }

                let fileURLs = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.creationDateKey], options: [])

                self.files = fileURLs.sorted {
                    let date1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    let date2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    return date1 > date2
                }

                selectedFile = files.first // ✅ Auto-select the most recent file

            } else {
                print("Failed to access security-scoped resource.")
            }
        } catch {
            print("Error accessing \(selectedFolder.rawValue) folder: \(error)")
        }
    }

    /// ✅ Starts monitoring the folder for new files
    private func startMonitoringFolder() {
        fileMonitor.startMonitoring(folder: selectedFolder) { newFile in
            DispatchQueue.main.async {
                refreshFiles()
                selectedFile = newFile // ✅ Auto-select newest file when detected
            }
        }
    }
}

#Preview {
    ContentView()
}
