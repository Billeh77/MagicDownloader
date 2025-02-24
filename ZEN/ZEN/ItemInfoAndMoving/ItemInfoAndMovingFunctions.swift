//
//  ItemInfoAndMovingFunctions.swift
//  ZEN
//
//  Created by Emile Billeh on 24/02/2025.
//

import SwiftUI
import Foundation

extension ItemInfoAndMovingView {
    
    /// ✅ Scroll to the selected folder & apply temporary highlight
    func highlightAndScrollToFolder(_ folder: URL, with proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.5)) {
                proxy.scrollTo(folder, anchor: .center) // ✅ Scroll to folder
            }

            highlightedFolder = folder // ✅ Track highlighted folder

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                highlightedFolder = nil // ✅ Remove highlight after 2 seconds
            }
        }
    }
    
    /// ✅ Handles the file drop operation
    func handleFileDrop(_ providers: [NSItemProvider], targetFolder: URL) -> Bool {
        if let provider = providers.first {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (data, error) in
                guard let data = data as? Data,
                      let droppedFileURL = URL(dataRepresentation: data, relativeTo: nil) else {
                    print("❌ Error: Could not retrieve dropped file URL")
                    return
                }
                
                DispatchQueue.main.async {
                    self.targetFolder = targetFolder
                    //                    self.fileURL = droppedFileURL
                    self.showMoveAlert = true
                }
            }
            return true
        }
        return false
    }
    
    /// ✅ Moves the file to the selected folder
    func moveFile() {
        guard let destinationFolder = targetFolder else {
            print("❌ Error: No destination folder selected")
            return
        }
        
        // ✅ Move file directly (No more security prompts)
        moveFile(to: destinationFolder)
    }
    
    /// ✅ Moves the file to the selected folder
    func moveFile(to destinationFolder: URL) {
        let destinationURL = destinationFolder.appendingPathComponent(fileName)
        
        do {
            // ✅ Ensure the file exists before attempting to move
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                print("❌ Error: Source file does not exist at \(fileURL.path)")
                return
            }
            
            // ✅ Ensure the destination folder exists, create if missing
            if !FileManager.default.fileExists(atPath: destinationFolder.path) {
                try FileManager.default.createDirectory(at: destinationFolder, withIntermediateDirectories: true, attributes: nil)
            }
            
            // ✅ Move the file
            try FileManager.default.moveItem(at: fileURL, to: destinationURL)
            print("✅ File successfully moved to: \(destinationURL.path)")
            
            // ✅ Update `fileURL` reference after move
            //            self.fileURL = destinationURL
        } catch {
            print("❌ Error moving file: \(error)")
        }
    }
    
    // ✅ Loads file metadata (creation date, modification date, origin)
    func loadFileMetadata() {
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
        
        // ✅ Retrieve and clean "Where from" information
        if var whereFromURL = getFileDownloadURL(fileURL) {
            if let lastSlashIndex = whereFromURL.range(of: "/", options: .backwards)?.lowerBound {
                let index = whereFromURL.index(after: lastSlashIndex)
                whereFromURL = String(whereFromURL[..<index]) // ✅ Trim everything after last `/`
            }
            originSource = whereFromURL
        } else {
            originSource = "Manually Created"
        }
    }
    
    /// ✅ Extracts the "Where from" metadata from macOS extended attributes
    func getFileDownloadURL(_ url: URL) -> String? {
        let attributeName = "com.apple.metadata:kMDItemWhereFroms"
        
        // ✅ Retrieve the extended attribute
        if let data = try? url.extendedAttribute(forName: attributeName) {
            if let urlArray = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String] {
                return urlArray.first // ✅ The first item usually contains the download URL
            }
        }
        
        return nil // ✅ No download origin found
    }
    
    // ✅ Formats a date to a readable string
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // ✅ Recursively scans Downloads, Desktop, and Documents for all folders
    func scanAvailableFolders() {
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
    
    
    func getSecureFolderAccess(for folder: URL, completion: @escaping (URL?) -> Void) {
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
    func requestFolderAccess(for folder: URL, completion: @escaping (URL?) -> Void) {
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
    func retrieveFolders(at rootURL: URL) -> [URL]? {
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
    
    // ✅ Saves the new file name
    func saveNewFileName() {
        if newFileName + fileExtension == fileName {
            isEditingName = false
            return
        }
        
        let newFilePath = fileURL.deletingLastPathComponent().appendingPathComponent(newFileName + fileExtension)
        
        do {
            try FileManager.default.moveItem(at: fileURL, to: newFilePath)
            print("✅ Successfully renamed file to: \(newFileName + fileExtension)")
            fileURL = newFilePath
        } catch {
            print("❌ Error renaming file: \(error)")
        }
        
        isEditingName = false
    }
    
    // ✅ Open the file
    func openFile() {
        NSWorkspace.shared.open(fileURL)
    }
    
    // ✅ Delete the file (Confirmation Needed)
    func deleteFile() {
        do {
            try FileManager.default.trashItem(at: fileURL, resultingItemURL: nil)
            print("File moved to trash: \(fileName)")
        } catch {
            print("Error deleting file: \(error)")
        }
    }
}
