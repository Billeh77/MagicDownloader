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
    @State private var isHovered = false // ✅ Track hover state

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
    }
}
