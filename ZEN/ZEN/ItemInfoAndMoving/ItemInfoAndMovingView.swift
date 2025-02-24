//
//  FileInfoAndMovingView.swift
//  ZEN
//
//  Created by Emile Billeh on 23/02/2025.
//

import SwiftUI
import Foundation

struct ItemInfoAndMovingView: View {
    @State var fileURL: URL
    
    // Extract file properties
    var fileName: String { fileURL.lastPathComponent }
    var fileExtension: String { fileURL.pathExtension.isEmpty ? "" : ".\(fileURL.pathExtension)" }
    var fileLocation: String { fileURL.deletingLastPathComponent().path }
    var fileType: FileTypeIcon { FileTypeIcon.from(url: fileURL) }
    
    @State var isEditingName = false
    @FocusState var isTextFieldFocused: Bool
    @State var newFileName = ""
    
    @State var creationDate: String = "Unknown"
    @State var modificationDate: String = "Unknown"
    @State var originSource: String = "Unknown"
    
    @State var availableFolders: [URL] = []
    
    @State var showDeleteAlert = false
    
    @State var searchText = "" // ✅ Track search input
    
    @State var showContentsView = false
    @State var selectedFolder: URL?
    @State var selectedFolderPosition: CGRect?
    @State var folderContents: [URL] = []
    
    @State var highlightedFolder: URL? = nil
    
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
    
    @State var showMoveAlert = false
    @State var targetFolder: URL?
    
    var body: some View {
        VStack(spacing: 0) {
            // ✅ Top Bar for File Info
            HStack {
                
                fileInformationView
                
                Spacer()
                
                actionButtons
            }
            .padding()
            
            // ✅ Divider to Separate Top Bar from Bottom Content
            Divider()
            
            InstructionsView()
            
            availableFoldersView
            
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
}

#Preview {
    ItemInfoAndMovingView(fileURL: URL(fileURLWithPath: "/Users/yourusername/Downloads/example.pdf"))
}



