import Foundation
import AppKit

class DownloadMonitor: ObservableObject {
    private var monitoredFolder: URL
    private var eventStream: FSEventStreamRef?
    private var timer: Timer?
    
    @Published var latestFile: URL?
    
    init() {
        monitoredFolder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        startMonitoring()
    }
    
    /// ✅ Uses FSEvents for **instantaneous** detection
    private func startMonitoring() {
        let path = monitoredFolder.path as NSString
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(), // ✅ Correctly pass self
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        eventStream = FSEventStreamCreate(nil, { (stream, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) in
            guard let clientCallBackInfo = clientCallBackInfo else { return } // ✅ Fix nil crash
            
            let monitor = Unmanaged<DownloadMonitor>.fromOpaque(clientCallBackInfo).takeUnretainedValue()
            monitor.checkForNewFiles()
        }, &context, [path] as CFArray, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0, UInt32(kFSEventStreamCreateFlagFileEvents))
        
        if let stream = eventStream {
            FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            FSEventStreamStart(stream)
            print("🚀 Using FSEvents for real-time download monitoring")
        } else {
            print("❌ Failed to initialize FSEvents, falling back to polling")
            startPolling()
        }
    }
    
    /// 🔄 **Backup:** Poll every 0.5 seconds (brute force)
    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.checkForNewFiles()
        }
    }
    
    private var lastDetectedFile: URL?
    
    private func checkForNewFiles() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: monitoredFolder, includingPropertiesForKeys: [.creationDateKey], options: [])
            
            guard let newest = contents.sorted(by: {
                let d1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let d2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return d1 > d2
            }).first else { return }
            
            guard newest != lastDetectedFile else { return } // ✅ Skip if same as before
            
            lastDetectedFile = newest
            let fileName = newest.lastPathComponent
            
            if fileName.hasPrefix(".com.google.Chrome") || fileName.hasSuffix(".crdownload") {
                print("⏳ Ignoring temporary Chrome download: \(fileName)")
                return
            }
            
            DispatchQueue.main.async {
                self.latestFile = newest
                NotificationCenter.default.post(name: .newDownloadDetected, object: newest)
                print("✅ New file detected: \(fileName)")
            }
        } catch {
            print("❌ Error scanning downloads: \(error)")
        }
    }
}

// ✅ Add Notification to Show the Menu Bar
extension Notification.Name {
    static let newDownloadDetected = Notification.Name("newDownloadDetected")
}
