import Cocoa
import FinderSync

class FinderSync: FIFinderSync {
    
    override init() {
        super.init()
        // 设置监控的路径。这里设置为根目录 /，表示监控所有 Finder 窗口
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
    }
    
    // 自定义右键菜单
    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let menu = NSMenu(title: "")
        
        // 仅在空白处右键 (contextualMenuForContainer) 时显示
        if menuKind == .contextualMenuForContainer {
            // 原来：let item = NSMenuItem(title: "新建文本文件", ...)
            let localizedTitle = NSLocalizedString("menu_new_file", comment: "")
            let item = NSMenuItem(title: localizedTitle, action: #selector(createNewFile), keyEquivalent: "")
            // 设置一个符合 Apple 风格的图标（SFSymbols）
            item.image = NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: nil)
            menu.addItem(item)
        }
        
        return menu
    }
    
    @objc func createNewFile() {
        guard let target = FIFinderSyncController.default().targetedURL() else { return }
        
        // 1. 获取用户设置的后缀，如果为空（首次运行），强制默认为 "txt"
        let groupID = "group.com.astronautJack.EasyNewFile" // 这里的 ID 记得改成你刚才在 App Group 填写的
        let sharedDefaults = UserDefaults(suiteName: groupID)
        let fileExtension = sharedDefaults?.string(forKey: "defaultExtension") ?? "txt"
        
        // 2. 准备文件名（这里可以根据后缀名灵活调整默认标题）
        let fileName = "未命名文件"
        var newFilePath = target.appendingPathComponent("\(fileName).\(fileExtension)")
        
        // 3. 自动递增编号逻辑 (防止覆盖已有文件)
        var count = 1
        while FileManager.default.fileExists(atPath: newFilePath.path) {
            count += 1
            newFilePath = target.appendingPathComponent("\(fileName) \(count).\(fileExtension)")
        }
        
        // 4. 沙盒安全写入
        let canAccess = target.startAccessingSecurityScopedResource()
        
        do {
            // 创建空数据
            let emptyData = "".data(using: .utf8) ?? Data()
            try emptyData.write(to: newFilePath, options: .atomic)
            
            // 5. 异步刷新并选中文件
            Task {
                // 通知系统该文件已更新（这会让文件立即在 Finder 中跳出来）
                await FIFinderSyncController.default().setLastUsedDate(Date(), forItemWith: newFilePath)
                // 激活 Finder 窗口并选中这个新创建的文件
                NSWorkspace.shared.activateFileViewerSelecting([newFilePath])
                //NSLog("EasyNewFile: 成功创建 \(fileExtension) 文件")
            }
        } catch {
            //NSLog("EasyNewFile 写入失败: \(error.localizedDescription)")
        }
        
        if canAccess {
            target.stopAccessingSecurityScopedResource()
        }
    }
}
