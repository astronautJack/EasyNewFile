import Cocoa
import FinderSync
import os.log

class FinderSync: FIFinderSync {
    
    let logger = OSLog(subsystem: "com.github.astronautJack.EasyNewFile", category: "FinderSync")
    
    override init() {
        super.init()
        
        // Use more specific and robust directories to monitor.
        // Monitoring "/" can be unreliable in a sandbox or cause performance issues.
        let usersURL = URL(fileURLWithPath: "/Users", isDirectory: true)
        let volumesURL = URL(fileURLWithPath: "/Volumes", isDirectory: true)
        
        FIFinderSyncController.default().directoryURLs = [usersURL, volumesURL]
        os_log("FinderSync init: Monitoring /Users and /Volumes", log: logger, type: .info)
    }
    
    // Custom context menu for Finder
    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let menu = NSMenu(title: "")
        
        // Only show the menu if we are in a container (background) and have a valid target URL.
        if menuKind == .contextualMenuForContainer {
            if let target = FIFinderSyncController.default().targetedURL(), target.isFileURL {
                let localizedTitle = NSLocalizedString("menu_new_file", comment: "")
                let item = NSMenuItem(title: localizedTitle, action: #selector(createNewFile), keyEquivalent: "")
                // Standard Apple SF Symbol for a new file
                item.image = NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: nil)
                menu.addItem(item)
            }
        }
        
        return menu
    }
    
    @objc func createNewFile() {
        // 1. Get the current folder. Resolve symlinks for consistency.
        guard let rawTarget = FIFinderSyncController.default().targetedURL() else {
            os_log("createNewFile: No targeted URL found.", log: logger, type: .error)
            return
        }
        let target = rawTarget.resolvingSymlinksInPath()
        
        // 2. Get user preferences for file extension from App Group.
        let groupID = "group.com.astronautJack.EasyNewFile"
        let sharedDefaults = UserDefaults(suiteName: groupID)
        let fileExtension = sharedDefaults?.string(forKey: "defaultExtension") ?? "txt"
        
        // 3. Prepare the localized default filename.
        let untitledName = NSLocalizedString("untitled_filename", comment: "Default filename for new files")
        var newFilePath = target.appendingPathComponent("\(untitledName).\(fileExtension)")
        
        // 4. Handle duplicates by incrementing a counter (e.g., "Untitled 2.txt").
        var count = 1
        while FileManager.default.fileExists(atPath: newFilePath.path) {
            count += 1
            newFilePath = target.appendingPathComponent("\(untitledName) \(count).\(fileExtension)")
        }
        
        // 5. Access security-scoped resource if provided by the system.
        let isSecurityScoped = target.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped {
                target.stopAccessingSecurityScopedResource()
            }
        }
        
        // 6. Create the empty file.
        // FileManager.createFile is often more reliable than Data.write in sandboxed extensions.
        let success = FileManager.default.createFile(atPath: newFilePath.path, contents: Data(), attributes: nil)
        
        if success {
            os_log("createNewFile: Successfully created file at %{public}@", log: logger, type: .info, newFilePath.path)
            
            // 7. Refresh and select the new file.
            Task { @MainActor in
                // Small delay to let Finder catch up with the filesystem change.
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                
                // Notify the system that the file was modified/accessed.
                await FIFinderSyncController.default().setLastUsedDate(Date(), forItemWith: newFilePath)
                
                // Focus Finder and select the file.
                NSWorkspace.shared.activateFileViewerSelecting([newFilePath])
            }
        } else {
            os_log("createNewFile: Failed to create file at %{public}@", log: logger, type: .error, newFilePath.path)
            
            // Potential reason: Permission denied or protected folder.
            // In a sandbox, writing to restricted system folders will fail.
        }
    }
}
