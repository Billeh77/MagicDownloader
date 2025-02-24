//
//  FolderType.swift
//  ZEN
//
//  Created by Emile Billeh on 23/02/2025.
//

import Foundation

enum FolderType: String, CaseIterable, Identifiable {
    case downloads = "Downloads"
    case documents = "Documents"
    case desktop = "Desktop"

    var id: String { self.rawValue }

    /// Returns the actual system URL for the folder
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

    /// The key used for storing security-scoped bookmarks
    var userDefaultsKey: String {
        "accessedFolder_\(self.rawValue)"
    }
}
