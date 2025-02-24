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
    
    var body: some View {
        VStack(spacing: 0) {
            // ✅ Top Bar for File Info
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
                
                Spacer()
                
                // ✅ Action Buttons
                HStack (spacing: 20) {
                    Button(action: openFile) {
                        VStack {
                            Image(systemName: "eye.fill")
                            Text("Open")
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    Button(action: viewSuggestedLocations) {
                        VStack {
                            Image(systemName: "map.fill")
                            Text("Suggested Locations")
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
            
            // ✅ Grid of All Available Folders
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                    ForEach(availableFolders, id: \.self) { folder in
                        VStack {
                            Image(systemName: "folder.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.accentColor)
                            
                            Text(folder.lastPathComponent)
                                .font(.headline)
                                .lineLimit(1)
                            
                            Text(folder.path)
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .padding()
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            
            Spacer() // Empty space below
        }
        .onAppear(perform: {
            loadFileMetadata()
            scanAvailableFolders()
        })
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
        let searchDirectories: [FolderType] = [.downloads, .desktop, .documents]
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
    
    private func getSecureFolderAccess(for folder: FolderType, completion: @escaping (URL?) -> Void) {
        let folderKey = folder.userDefaultsKey

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
                print("Error resolving bookmark for \(folder.rawValue): \(error)")
            }
        }

        // ✅ If no bookmark exists, request folder access
        requestFolderAccess(for: folder, completion: completion)
    }

    
    private func requestFolderAccess(for folder: FolderType, completion: @escaping (URL?) -> Void) {
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
        do {
            let folderContents = try FileManager.default.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])

            let folders = folderContents.filter { url in
                var isDirectory: ObjCBool = false
                return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
            }

            return folders
        } catch {
            print("Error accessing \(rootURL.path): \(error)")
            return nil
        }
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

