# MacOCRClip (菜单栏：截图 → OCR → 剪贴板)

目标：按快捷键后进入选区截图，松开鼠标后自动 OCR（Vision），并将纯文本写入剪贴板。

## 推荐构建方式（最省事）
1. 在 macOS 上用 Xcode 创建一个 **App**（macOS / SwiftUI）项目：`MacOCRClip`
2. 删除/替换 Xcode 生成的 `ContentView.swift` 等文件
3. 将本目录 `MacOCRClip/App` 下的 `.swift` 文件全部加入 Xcode target（勾选 Copy items if needed）
4. 在 `Signing & Capabilities` 里保持默认（无需额外 entitlements）。
5. 运行。

> 备注：不同 macOS 版本对“屏幕内容采集”权限要求不同。若首次运行无法截屏，请到：
> 系统设置 → 隐私与安全性 → **屏幕录制**，勾选 `MacOCRClip`。

## 默认快捷键
- `⌥ Option + ⇧ Shift + O`

可在 `HotKeyManager.swift` 里改。

## 行为
- 触发快捷键后，会弹出一个全屏透明遮罩。
- 用鼠标拖拽框选区域，松开后：
  - 截图该区域
  - OCR 识别（zh-Hans + en-US）
  - 将结果写入剪贴板（纯文本）
  - 右上角发一个系统通知提示

## 代码结构
- `MacOCRClipApp.swift`：MenuBarExtra 入口
- `HotKeyManager.swift`：全局快捷键（Carbon RegisterEventHotKey）
- `SelectionOverlayController.swift`：全屏选区 UI（NSWindow + NSView）
- `ScreenGrabber.swift`：从选区 rect 截图（CGWindowListCreateImage）
- `OCRService.swift`：Vision OCR
- `ClipboardService.swift`：写入 NSPasteboard
- `NotifyService.swift`：通知提示

## 已知限制（MVP 范围内接受）
- 只做纯文本，不重建排版。
- OCR 失败/无文字会提示并写入空字符串（可改成不覆盖剪贴板）。

