import SwiftUI

@main
struct MacOCRClipApp: App {
    @StateObject private var hotKey = HotKeyManager.shared

    var body: some Scene {
        MenuBarExtra("OCR", systemImage: "text.viewfinder") {
            Button("截图识别（⌥⇧O）") {
                Task { await Self.runFlow() }
            }
            .keyboardShortcut("o", modifiers: [.option, .shift]) // 菜单内快捷键（非全局）

            Divider()

            Button("退出") {
                NSApp.terminate(nil)
            }
        }
        .menuBarExtraStyle(.window)
        .onAppear {
            hotKey.start()
        }
    }

    static func runFlow() async {
        do {
            let text = try await ScreenshotOCRFlow.runInteractiveScreenshotOCR()
            ClipboardService.writeText(text)

            let preview = text.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            if preview.isEmpty {
                NotifyService.notify(title: "OCR", body: "未检测到文字（已复制空文本）")
            } else {
                NotifyService.notify(title: "OCR", body: "已复制：\(preview.prefix(30))")
            }
        } catch {
            NotifyService.notify(title: "OCR", body: "失败：\(error.localizedDescription)")
        }
    }
}
