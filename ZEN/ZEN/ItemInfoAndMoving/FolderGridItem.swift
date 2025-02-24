//
//  FolderGridItem.swift
//  ZEN
//
//  Created by Emile Billeh on 23/02/2025.
//


import SwiftUI
import Foundation

struct FolderGridItem: View {
    let folder: URL
    var onSelectFolder: (URL) -> Void // ✅ Callback when a folder is clicked inside the context menu
    
    @State private var isHovered = false // ✅ Track hover state
    @State private var folderContents: [URL] = [] // ✅ Store folder contents

    var body: some View {
        VStack(alignment: .center) {
            Image(systemName: "folder.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundColor(.accentColor)

            Text(folder.lastPathComponent)
                .font(.headline)
                .lineLimit(isHovered ? 3 : 1) // ✅ Expand on hover
            
            Text(folder.path)
                .font(.system(size: 10))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(isHovered ? 5 : 2) // ✅ Expand on hover
        }
        .frame(width: 150, height: 150) // ✅ Fixed height to prevent movement
        .padding()
        .cornerRadius(8)
        .scaleEffect(isHovered ? 1.1 : 1.0) // ✅ Subtle enlargement effect
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering // ✅ Toggle hover state
        }
        .contextMenu { // ✅ Right-click menu for folder contents
            if folderContents.isEmpty {
                Text("Loading...") // ✅ Show while loading
            } else {
                ForEach(folderContents, id: \.self) { item in
                    Button(action: {
                        onSelectFolder(item) // ✅ Scroll to this folder in the grid
                    }) {
                        HStack {
                            Image(systemName: FileTypeIcon.from(url: item).symbolName)
                                .foregroundColor(.blue)
                            Text(item.lastPathComponent)
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 2)
                    }
                    .disabled(!item.hasDirectoryPath)
                }
            }
        }
        .onAppear {
            loadFolderContents() // ✅ Load folder contents on view load
        }
    }

    /// ✅ Loads the folder’s files & subfolders
    private func loadFolderContents() {
        DispatchQueue.global(qos: .background).async {
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
                DispatchQueue.main.async {
                    folderContents = contents
                }
            } catch {
                print("Error loading folder contents: \(error)")
                DispatchQueue.main.async {
                    folderContents = []
                }
            }
        }
    }
}
