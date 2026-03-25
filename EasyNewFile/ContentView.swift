import SwiftUI

struct ContentView: View {
    @AppStorage("defaultExtension", store: UserDefaults(suiteName: "group.com.astronautJack.EasyNewFile"))
    var defaultExtension: String = "txt"
    
    let formats = ["txt", "md", "swift", "py", "docx", "xlsx"]
    
    var body: some View {
        VStack(spacing: 0) {
            // --- 顶部 Header ---
            VStack(spacing: 10) {
                Image(nsImage: NSApplication.shared.applicationIconImage) // 如果没生效可以改回 systemSymbolName: "doc.badge.plus"
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 64, height: 64)
                
                Text("app_name") // 使用 Key
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                Link("https://github.com/astronautJack/EasyNewFile", destination: URL(string: "https://github.com/astronautJack/EasyNewFile")!)
                    .font(.caption)
            }
            .padding(.top, 30)
            .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    // --- 1. 格式设置卡片 ---
                    GroupBox(label: Label("setting_title", systemImage: "gearshape")) {                         VStack(alignment: .leading, spacing: 12) {
                        Text("select_format") // 使用 Key
                            .font(.subheadline)
                        
                        Picker("", selection: $defaultExtension) {
                            ForEach(formats, id: \.self) { format in
                                Text(".\(format)").tag(format)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    .padding(.vertical, 8)
                    }
                    
                    // --- 2. 资源占用说明卡片 (体现轻量化) ---
                    GroupBox(label: Label("perf_privacy", systemImage: "leaf")) {
                        VStack(alignment: .leading, spacing: 10) {
                            InfoRow(icon: "bolt.fill", color: .yellow, text: NSLocalizedString("low_energy", comment: ""))
                            InfoRow(icon: "memorychip", color: .blue, text: NSLocalizedString("memory_usage", comment: ""))
                            InfoRow(icon: "network.slash", color: .green, text: NSLocalizedString("offline_safe", comment: ""))
                        }
                        .padding(.vertical, 5)
                    }
                    
                    // --- 3. ⚠️ 重要提示 (防止误删) ---
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("warning_title")
                                .fontWeight(.bold)
                        }
                        Text("warning_body") // 使用 Key
                            .font(.caption)
                            .lineSpacing(4)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
                    
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
            }
            
            // --- 底部操作栏 ---
            VStack(spacing: 12) {
                Divider()
                Button(action: openSystemSettings) {
                    Label("open_settings", systemImage: "arrow.up.forward.app") // 使用 Key
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
                .padding(.top, 10)
            }
            .background(VisualEffectView(material: .windowBackground, blendingMode: .withinWindow))
        }
        .frame(minWidth: 480, maxWidth: 480, minHeight: 600, maxHeight: 650)
    }
    
    func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences")!
        NSWorkspace.shared.open(url)
    }
}

// 辅助视图：信息行
struct InfoRow: View {
    var icon: String
    var color: Color
    var text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 16)
            Text(text)
                .font(.subheadline)
        }
    }
}

// 辅助视图：高斯模糊背景（更契合苹果风格）
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
