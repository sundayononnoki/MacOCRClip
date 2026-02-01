import AppKit

/// 负责显示全屏透明遮罩，让用户拖拽框选区域。
/// 松开鼠标后：截图 → OCR → 剪贴板 → 通知。
@MainActor
final class SelectionOverlayController: NSObject {
    static let shared = SelectionOverlayController()

    private var windows: [NSWindow] = []
    private var overlayViews: [SelectionOverlayView] = []

    private override init() {
        super.init()
    }

    func beginSelection() {
        // 如果已经在选区状态，先清理
        endSelection()

        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false,
                screen: screen
            )

            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .screenSaver // 覆盖全屏应用
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
            window.ignoresMouseEvents = false
            window.hasShadow = false

            let view = SelectionOverlayView(frame: screen.frame)
            view.onComplete = { [weak self] selectionRect in
                guard let self else { return }
                Task {
                    await self.handleSelection(rect: selectionRect)
                }
            }

            window.contentView = view
            window.makeKeyAndOrderFront(nil)

            windows.append(window)
            overlayViews.append(view)
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    func endSelection() {
        overlayViews.removeAll()
        for w in windows {
            w.orderOut(nil)
        }
        windows.removeAll()
    }

    private func handleSelection(rect: CGRect) async {
        endSelection()

        guard rect.width >= 2, rect.height >= 2 else {
            NotifyService.notify(title: "OCR", body: "选区太小")
            return
        }

        guard let cgImage = ScreenGrabber.capture(rect: rect) else {
            NotifyService.notify(title: "OCR", body: "截图失败（可能缺少屏幕录制权限）")
            return
        }

        do {
            let text = try await OCRService.recognizeText(from: cgImage)
            let cleaned = OCRService.clean(text)
            ClipboardService.writeText(cleaned)

            if cleaned.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                NotifyService.notify(title: "OCR", body: "未检测到文字（已复制空文本）")
            } else {
                let preview = cleaned
                    .replacingOccurrences(of: "\n", with: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let short = String(preview.prefix(30))
                NotifyService.notify(title: "OCR", body: "已复制：\(short)")
            }
        } catch {
            NotifyService.notify(title: "OCR", body: "识别失败：\(error.localizedDescription)")
        }
    }
}

/// 全屏遮罩视图：拖拽框选
final class SelectionOverlayView: NSView {
    var onComplete: ((CGRect) -> Void)?

    private var isDragging = false
    private var startPoint: CGPoint = .zero
    private var currentPoint: CGPoint = .zero

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // 背景遮罩
        NSColor.black.withAlphaComponent(0.25).setFill()
        dirtyRect.fill()

        guard isDragging else { return }

        let rect = selectionRect()

        // 在选区内“挖空”一点点（更清晰）
        NSColor.clear.setFill()
        NSBezierPath(rect: rect).fill(using: .clear)

        // 选区边框
        NSColor.systemBlue.withAlphaComponent(0.9).setStroke()
        let path = NSBezierPath(rect: rect)
        path.lineWidth = 2
        path.stroke()
    }

    override func mouseDown(with event: NSEvent) {
        isDragging = true
        startPoint = event.locationInWindow
        currentPoint = startPoint
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        currentPoint = event.locationInWindow
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard isDragging else { return }
        currentPoint = event.locationInWindow
        isDragging = false
        needsDisplay = true

        // 转换为全局屏幕坐标（重要：CG 截图用全局坐标）
        guard let window else { return }
        let rectInWindow = selectionRect()
        let rectInScreen = window.convertToScreen(rectInWindow)

        onComplete?(rectInScreen)
    }

    override func keyDown(with event: NSEvent) {
        // ESC 取消
        if event.keyCode == 53 {
            SelectionOverlayController.shared.endSelection()
        }
    }

    private func selectionRect() -> CGRect {
        let x = min(startPoint.x, currentPoint.x)
        let y = min(startPoint.y, currentPoint.y)
        let w = abs(startPoint.x - currentPoint.x)
        let h = abs(startPoint.y - currentPoint.y)
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
