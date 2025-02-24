import Foundation
import AppKit

class FileMonitor: ObservableObject {
    private var source: DispatchSourceFileSystemObject?
    private var monitoredFolderURL: URL?
    private var fileDescriptor: CInt = -1

    func startMonitoring(folder: ContentView.FolderType) {
        stopMonitoring() // Clean up previous monitoring

        guard let folderURL = folder.directoryURL else { return }
        monitoredFolderURL = folderURL
        
        do {
            let bookmarkData = UserDefaults.standard.data(forKey: folder.userDefaultsKey)
            var isStale = false
            let resolvedURL = try URL(resolvingBookmarkData: bookmarkData ?? Data(), 
                                      options: .withSecurityScope, 
                                      relativeTo: nil, 
                                      bookmarkDataIsStale: &isStale)
            
            if isStale {
                print("Bookmark stale, requesting access again.")
                return
            }
            
            if resolvedURL.startAccessingSecurityScopedResource() {
                defer { resolvedURL.stopAccessingSecurityScopedResource() }
                
                fileDescriptor = open(resolvedURL.path, O_EVTONLY)
                if fileDescriptor == -1 {
                    print("Failed to open directory for monitoring.")
                    return
                }

                let queue = DispatchQueue.global(qos: .background)
                source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: .write, queue: queue)

                source?.setEventHandler {
                    self.handleFolderChange()
                }
                
                source?.setCancelHandler {
                    close(self.fileDescriptor)
                    self.fileDescriptor = -1
                }
                
                source?.resume()
            }
        } catch {
            print("Error resolving security-scoped bookmark: \(error)")
        }
    }

    func stopMonitoring() {
        source?.cancel()
        source = nil
        if fileDescriptor != -1 {
            close(fileDescriptor)
        }
    }

    private func handleFolderChange() {
        guard let folderURL = monitoredFolderURL else { return }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: folderURL, 
                                                                   includingPropertiesForKeys: [.creationDateKey], 
                                                                   options: [])
            
            let sortedFiles = files.sorted {
                let date1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 > date2
            }

            if let newestFile = sortedFiles.first {
                print("New file detected: \(newestFile.lastPathComponent)")
                DispatchQueue.main.async {
                    self.bringAppToFront()
                }
            }
        } catch {
            print("Error reading directory contents: \(error)")
        }
    }

    private func bringAppToFront() {
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
