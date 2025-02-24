//
//  FileInfoAndMovingView.swift
//  ZEN
//
//  Created by Emile Billeh on 23/02/2025.
//

import SwiftUI
import Foundation

struct FileInfoAndMovingView: View {
    let fileURL: URL
    
    // Extract file properties
    private var fileName: String { fileURL.lastPathComponent }
    private var fileLocation: String { fileURL.deletingLastPathComponent().path }
    private var fileType: FileTypeIcon { FileTypeIcon.from(url: fileURL) }
    
    @State private var creationDate: String = "Unknown"
    @State private var modificationDate: String = "Unknown"
    @State private var originSource: String = "Unknown"
    
    @State private var availableFolders: [URL] = []
    
    @State private var showDeleteAlert = false
    
    @State private var searchText = "" // ✅ Track search input
    
    var filteredFolders: [URL] {
        if searchText.isEmpty {
            return availableFolders
        } else {
            return availableFolders.filter { folder in
                folder.lastPathComponent.localizedCaseInsensitiveContains(searchText) ||
                folder.path.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    @State private var showMoveAlert = false
    @State private var targetFolder: URL?
    
    var body: some View {
        VStack(spacing: 0) {
            // ✅ Top Bar for File Info
            HStack {
                
                HStack {
                    // ✅ File Icon
                    Image(systemName: fileType.symbolName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .foregroundColor(.accentColor)
                    
                    // ✅ File Details
                    VStack(alignment: .leading, spacing: 2) {
                        Text(fileName)
                            .font(.headline)
                            .bold()
                        Text("Location: \(fileLocation)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Created: \(creationDate)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Modified: \(modificationDate)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Origin: \(originSource)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .onDrag {
                    return NSItemProvider(object: fileURL as NSURL)
                } // ✅ Makes the icon & name draggable
                
                Spacer()
                
                // ✅ Action Buttons
                HStack (spacing: 30) {
                    Button(action: openFile) {
                        VStack {
                            Image(systemName: "eye.fill")
                            Text("Open")
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    Button(action: {
                        showDeleteAlert = true // ✅ Show confirmation alert before deleting
                    }) {
                        VStack {
                            Image(systemName: "trash.fill")
                            Text("Delete")
                        }
                    }
                    .foregroundStyle(.red)
                    .buttonStyle(BorderlessButtonStyle())
                    .alert("Move to Trash?", isPresented: $showDeleteAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Move to Trash", role: .destructive) {
                            deleteFile() // ✅ Only delete if user confirms
                        }
                    } message: {
                        Text("Are you sure you want to move \"\(fileName)\" to the Trash? This action cannot be undone.")
                    }
                }
            }
            .padding()
            
            // ✅ Divider to Separate Top Bar from Bottom Content
            Divider()
            
            Text("Drag and drop the item above into the desired folder")
                .padding(.vertical)
                .font(.headline)
            
            // ✅ Grid of All Available Folders
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                    ForEach(filteredFolders, id: \.self) { folder in
                        FolderGridItem(folder: folder)
                            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                                handleFileDrop(providers, targetFolder: folder)
                            } // ✅ Allow dropping files into folders
                    }
                }
                .padding()
            }
            .searchable(text: $searchText, prompt: "Search Folders")
            
            Spacer() // Empty space below
        }
        .onAppear(perform: {
            loadFileMetadata()
            scanAvailableFolders()
        })
        .alert("Move File?", isPresented: $showMoveAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Move", role: .destructive) {
                moveFile()
            }
        } message: {
            Text("Are you sure you want to move \"\(fileName)\" to \"\(targetFolder?.lastPathComponent ?? "")\"?")
        }
    }
    
    
    // ✅ Handles the file drop operation
    private func handleFileDrop(_ providers: [NSItemProvider], targetFolder: URL) -> Bool {
        if let provider = providers.first {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (data, error) in
                guard let data = data as? Data, let fileURL = URL(dataRepresentation: data, relativeTo: nil) else { return }
                
                DispatchQueue.main.async {
                    self.targetFolder = targetFolder
                    self.showMoveAlert = true
                }
            }
            return true
        }
        return false
    }
    
    /// ✅ Moves the file to the selected folder
    private func moveFile() {
        guard let destinationFolder = targetFolder else { return }

        // ✅ Request permission if destination folder is not already accessible
        requestFolderAccess(for: destinationFolder) { grantedFolder in
            if let grantedFolder = grantedFolder {
                moveFile(to: grantedFolder) // ✅ Move after access is granted
            } else {
                print("⚠️ User did not grant access to \(destinationFolder.path)")
            }
        }
    }
    
    /// ✅ Allows user to select any folder for moving the file
    private func requestManualFolderAccess(for folder: URL) {
        let openPanel = NSOpenPanel()
        openPanel.message = "Please grant access to move the file into \(folder.lastPathComponent)"
        openPanel.prompt = "Allow"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.directoryURL = folder

        if openPanel.runModal() == .OK, let selectedURL = openPanel.url {
            moveFile(to: selectedURL) // ✅ Move the file after getting access
        } else {
            print("User denied access to \(folder.path)")
        }
    }

    /// ✅ Moves the file after gaining access
    private func moveFile(to destinationFolder: URL) {
        let destinationURL = destinationFolder.appendingPathComponent(fileName)

        // ✅ Ensure security-scoped access before moving
        if destinationFolder.startAccessingSecurityScopedResource() {
            do {
                try FileManager.default.moveItem(at: fileURL, to: destinationURL)
                print("✅ File successfully moved to: \(destinationURL.path)")
            } catch {
                print("❌ Error moving file: \(error)")
            }
            destinationFolder.stopAccessingSecurityScopedResource() // ✅ Release access after moving
        } else {
            print("❌ Failed to access security-scoped resource for \(destinationFolder.path)")
        }
    }
    
    private func getStoredFolderAccess(for folderName: String) -> URL? {
        if let bookmarkData = UserDefaults.standard.data(forKey: "savedFolderBookmark_\(folderName)") {
            do {
                var isStale = false
                let folderURL = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                
                if isStale {
                    print("Bookmark data is stale. Requesting permission again.")
                    return nil
                }

                if folderURL.startAccessingSecurityScopedResource() {
                    return folderURL
                }
            } catch {
                print("Error retrieving bookmark: \(error)")
            }
        }
        return nil
    }
    
    // ✅ Loads file metadata (creation date, modification date, origin)
    private func loadFileMetadata() {
        let resourceKeys: Set<URLResourceKey> = [.creationDateKey, .contentModificationDateKey]
        
        do {
            let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)
            if let createdDate = resourceValues.creationDate {
                creationDate = formatDate(createdDate)
            }
            if let modifiedDate = resourceValues.contentModificationDate {
                modificationDate = formatDate(modifiedDate)
            }
        } catch {
            print("Error fetching file metadata: \(error)")
        }
        
        // ✅ Check if file came from the internet
        if fileURL.absoluteString.hasPrefix("http") {
            originSource = fileURL.absoluteString
        } else {
            originSource = "Manually Created"
        }
    }
    
    // ✅ Formats a date to a readable string
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // ✅ Recursively scans Downloads, Desktop, and Documents for all folders
    private func scanAvailableFolders() {
        let searchDirectories: [URL] = [
            FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first,
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
            FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
        ].compactMap { $0 } // ✅ Ensure non-nil values
        
        var discoveredFolders: [URL] = []
        
        let group = DispatchGroup()
        
        for folder in searchDirectories {
            group.enter()
            getSecureFolderAccess(for: folder) { folderURL in
                if let folderURL = folderURL {
                    if let folderList = retrieveFolders(at: folderURL) {
                        discoveredFolders.append(contentsOf: folderList)
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.availableFolders = discoveredFolders // ✅ Update folders after all requests complete
        }
    }

    
    private func getSecureFolderAccess(for folder: URL, completion: @escaping (URL?) -> Void) {
        let folderKey = "savedFolderBookmark_\(folder.lastPathComponent)"

        // ✅ Check if a stored security-scoped bookmark exists
        if let bookmarkData = UserDefaults.standard.data(forKey: folderKey) {
            do {
                var isStale = false
                let folderURL = try URL(resolvingBookmarkData: bookmarkData,
                                        options: .withSecurityScope,
                                        relativeTo: nil,
                                        bookmarkDataIsStale: &isStale)

                if isStale {
                    print("Bookmark data is stale. Requesting permission again.")
                    requestFolderAccess(for: folder, completion: completion)
                    return
                }

                if folderURL.startAccessingSecurityScopedResource() {
                    completion(folderURL) // ✅ Successfully accessed stored folder
                    return
                } else {
                    print("Failed to access security-scoped resource.")
                }
            } catch {
                print("Error resolving bookmark for \(folder.path): \(error)")
            }
        }

        // ✅ If no bookmark exists, request folder access
        requestFolderAccess(for: folder, completion: completion)
    }

    
    
    /// ✅ Requests access to the given folder and stores a security-scoped bookmark
    private func requestFolderAccess(for folder: URL, completion: @escaping (URL?) -> Void) {
        DispatchQueue.main.async {
            let openPanel = NSOpenPanel()
            openPanel.message = "Please grant access to \(folder.lastPathComponent)"
            openPanel.prompt = "Allow"
            openPanel.canChooseFiles = false
            openPanel.canChooseDirectories = true
            openPanel.allowsMultipleSelection = false
            openPanel.directoryURL = folder

            if openPanel.runModal() == .OK, let selectedURL = openPanel.url {
                do {
                    let bookmarkData = try selectedURL.bookmarkData(options: .withSecurityScope,
                                                                    includingResourceValuesForKeys: nil,
                                                                    relativeTo: nil)

                    UserDefaults.standard.set(bookmarkData, forKey: "savedFolderBookmark_\(folder.lastPathComponent)")
                    completion(selectedURL) // ✅ Return the selected folder asynchronously
                    return
                } catch {
                    print("Error creating security-scoped bookmark: \(error)")
                }
            }

            completion(nil) // ✅ If access fails, return nil
        }
    }

    
    
    // ✅ Retrieves all folders within a given directory
    private func retrieveFolders(at rootURL: URL) -> [URL]? {
        var folders: [URL] = []
        
        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [.isDirectoryKey]
        
        // ✅ Use enumerator to traverse all subdirectories
        if let enumerator = fileManager.enumerator(at: rootURL, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
            print("Error accessing \(url.path): \(error)")
            return true // Continue enumeration even if some folders fail
        }) {
            for case let url as URL in enumerator {
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
                    folders.append(url) // ✅ Add only directories
                }
            }
        }
        
        return folders
    }
    
    // ✅ Open the file
    private func openFile() {
        NSWorkspace.shared.open(fileURL)
    }
    
    // ✅ Show suggested locations (Placeholder)
    private func viewSuggestedLocations() {
        print("Viewing suggested locations for \(fileName)")
    }
    
    // ✅ Delete the file (Confirmation Needed)
    private func deleteFile() {
        do {
            try FileManager.default.trashItem(at: fileURL, resultingItemURL: nil)
            print("File moved to trash: \(fileName)")
        } catch {
            print("Error deleting file: \(error)")
        }
    }
}

#Preview {
    FileInfoAndMovingView(fileURL: URL(fileURLWithPath: "/Users/yourusername/Downloads/example.pdf"))
}


