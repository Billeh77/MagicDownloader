//
//  ItemInfoAndMovingComponents.swift
//  ZEN
//
//  Created by Emile Billeh on 24/02/2025.
//

import SwiftUI
import Foundation

extension ItemInfoAndMovingView {
    
    var fileInformationView: some View {
        HStack {
            // ✅ File Icon
            Image(systemName: fileType.symbolName)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundColor(.accentColor)
            
            // ✅ File Details
            VStack(alignment: .leading, spacing: 2) {
                if isEditingName {
                    // ✅ Editable TextField for Renaming
                    TextField("", text: $newFileName, onCommit: saveNewFileName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: min(300, CGFloat(newFileName.count * 10))) // ✅ Dynamic width
                        .focused($isTextFieldFocused) // ✅ Focuses textfield automatically
                        .onAppear {
                            newFileName = fileName.replacingOccurrences(of: fileExtension, with: "")
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isTextFieldFocused = true  // ✅ Force focus on appear
                            }
                        }
                        .onExitCommand {
                            isEditingName = false
                        }
                } else {
                    // ✅ Regular Display Mode
                    Text(fileName)
                        .font(.headline)
                        .bold()
                }
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
    }
    
    var actionButtons: some View {
        // ✅ Action Buttons
        HStack (spacing: 30) {
            
            // ✅ Rename Button
            Button(action: {
                if isEditingName {
                    saveNewFileName()
                } else {
                    isEditingName.toggle()
                }
            }) {
                VStack {
                    Image(systemName: "pencil.tip")
                    Text("Rename")
                }
            }
            .buttonStyle(BorderlessButtonStyle())
            
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
    
    var availableFoldersView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                    ForEach(filteredFolders, id: \.self) { folder in
                        FolderGridItem(folder: folder, onSelectFolder: { selectedFolder in
                            highlightAndScrollToFolder(selectedFolder, with: scrollProxy)
                        })
                        .id(folder) // ✅ Ensure each folder has a unique scroll ID
                        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                            handleFileDrop(providers, targetFolder: folder)
                        }
                        .background(highlightedFolder == folder ? Color.blue.opacity(0.2) : Color.clear)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .searchable(text: $searchText, prompt: "Search Folders")
        }
    }



}
