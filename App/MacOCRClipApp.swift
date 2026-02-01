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
        await MainActor.run {
            SelectionOverlayController.shared.beginSelection()
        }
    }
}
