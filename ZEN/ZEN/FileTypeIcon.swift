//
//  FileTypeIcon.swift
//  ZEN
//
//  Created by Emile Billeh on 23/02/2025.
//

enum FileTypeIcon {
    case folder, document, image, video, pdf, code, audio, archive, system

    /// Returns an appropriate SF Symbol for each file type
    var symbolName: String {
        switch self {
        case .folder: return "folder.fill"
        case .document: return "doc.fill"
        case .image: return "photo.fill"
        case .video: return "film.fill"
        case .pdf: return "doc.richtext.fill"
        case .code: return "chevron.left.slash.chevron.right"
        case .audio: return "waveform"
        case .archive: return "archivebox.fill"
        case .system: return "gearshape.fill"
        }
    }

    /// Determines the file type from a given URL
    static func fromFileExtension(_ fileExtension: String) -> FileTypeIcon {
        switch fileExtension.lowercased() {
        case "jpg", "jpeg", "png", "gif", "tiff", "bmp", "heic":
            return .image
        case "mp4", "mov", "avi", "mkv", "wmv":
            return .video
        case "pdf":
            return .pdf
        case "zip", "rar", "7z", "tar":
            return .archive
        case "mp3", "wav", "m4a", "flac":
            return .audio
        case "swift", "js", "html", "css", "py", "java", "c", "cpp":
            return .code
        case "system":
            return .system
        default:
            return .document
        }
    }
}
