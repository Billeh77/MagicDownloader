//
//  FileInfoAndMovingView.swift
//  ZEN
//
//  Created by Emile Billeh on 23/02/2025.
//

import SwiftUI

struct FileInfoAndMovingView: View {
    let fileURL: URL
    
    // Extract file properties
    private var fileName: String { fileURL.lastPathComponent }
    private var fileLocation: String { fileURL.deletingLastPathComponent().path }
    private var fileType: FileTypeIcon { FileTypeIcon.fromFileExtension(fileURL.pathExtension) }
    
    @State private var creationDate: String = "Unknown"
    @State private var modificationDate: String = "Unknown"
    @State private var originSource: String = "Unknown"

    var body: some View {
        VStack(spacing: 0) {
            // ✅ Top Bar for File Info
            HStack {
                // ✅ File Icon
                Image(systemName: fileType.symbolName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
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

                    Button(action: deleteFile) {
                        VStack {
                            Image(systemName: "trash.fill")
                            Text("Delete")
                        }
                    }
                    .foregroundStyle(.red)
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding()
            
            // ✅ Divider to Separate Top Bar from Bottom Content
            Divider()
            
            Spacer() // Empty space below
        }
        .onAppear(perform: loadFileMetadata)
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
