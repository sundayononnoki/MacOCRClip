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

## 行为（macOS 15+ 兼容版）
- 触发快捷键后，会调用系统自带 `/usr/sbin/screencapture` 进入交互式选区（系统截图 UI）。
- 选区完成后截图会先进入**剪贴板（图片）**，然后 App：
  - 从剪贴板读取图片
  - Vision OCR 识别（zh-Hans + en-US）
  - 将识别结果写回剪贴板（纯文本）
  - 右上角发一个系统通知提示

> 为什么改成这样：macOS 15 之后，应用内直接抓屏（CGWindowListCreateImage 等）更容易遇到权限/黑屏/失败。
> 让系统截图进程完成采集是目前最稳的方式。

## 代码结构
- `MacOCRClipApp.swift`：MenuBarExtra 入口
- `HotKeyManager.swift`：全局快捷键（Carbon RegisterEventHotKey）
- `ScreenshotOCRFlow.swift`：调用系统 screencapture 交互式截图 → 读取剪贴板图片 → OCR
- `OCRService.swift`：Vision OCR
- `ClipboardService.swift`：写入 NSPasteboard
- `NotifyService.swift`：通知提示

## 已知限制（MVP 范围内接受）
- 只做纯文本，不重建排版。
- OCR 失败/无文字会提示，并默认仍会把结果写入剪贴板（可按需改为“空结果不覆盖剪贴板”）。
- 依赖系统 `/usr/sbin/screencapture`：如果用户取消选区（ESC），会提示“已取消”。

