import Cocoa
import FinderSync

class FinderSync: FIFinderSync {
    
    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let menu = NSMenu(title: "")
        if menuKind == .contextualMenuForContainer {
            let localizedTitle = NSLocalizedString("menu_new_file", comment: "")
            let item = NSMenuItem(title: localizedTitle, action: #selector(FinderSync.createNewFile), keyEquivalent: "")
            item.image = NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: nil)
            item.target = self
            menu.addItem(item)
        }
        return menu
    }
    
    @objc func createNewFile() {
        guard let targetURL = FIFinderSyncController.default().targetedURL()?.standardizedFileURL else {
            return
        }
        
        let groupID = "group.com.astronautJack.EasyNewFile"
        let sharedDefaults = UserDefaults(suiteName: groupID)
        let fileExtension = sharedDefaults?.string(forKey: "defaultExtension") ?? "txt"
        
        let fileName = "Untitled"
        var newFileURL = targetURL.appendingPathComponent("\(fileName).\(fileExtension)")
        var count = 1
        while FileManager.default.fileExists(atPath: newFileURL.path) {
            newFileURL = targetURL.appendingPathComponent("\(fileName) \(count).\(fileExtension)")
            count += 1
        }
        
        let success = FileManager.default.createFile(atPath: newFileURL.path, contents: Data(), attributes: nil)
        
        if success {
            Task { @MainActor in
                await FIFinderSyncController.default().setLastUsedDate(Date(), forItemWith: newFileURL)
                NSWorkspace.shared.activateFileViewerSelecting([newFileURL])
            }
        }
    }
}
