import AppKit

enum ScreenshotOCRFlow {
    enum FlowError: LocalizedError {
        case screenshotCancelled
        case screenshotFailed(String)
        case noImageInClipboard
        case timeoutWaitingForClipboard

        var errorDescription: String? {
            switch self {
            case .screenshotCancelled: return "已取消"
            case .screenshotFailed(let s): return "截图失败：\(s)"
            case .noImageInClipboard: return "截图完成但剪贴板里没有图片"
            case .timeoutWaitingForClipboard: return "等待剪贴板图片超时"
            }
        }
    }

    /// macOS 15+ 更稳的路径：调用系统 screencapture 进入交互式选区（由系统进程采集屏幕），
    /// 结果写入剪贴板（图片），然后我们从剪贴板读取图片做 Vision OCR。
    static func runInteractiveScreenshotOCR(timeoutSeconds: TimeInterval = 8) async throws -> String {
        let pb = NSPasteboard.general
        let beforeChange = pb.changeCount

        try await ScreencaptureCLI.runInteractiveCopyToClipboard()

        // 等待剪贴板变化并出现图片
        let deadline = Date().addingTimeInterval(timeoutSeconds)
        while Date() < deadline {
            if pb.changeCount != beforeChange {
                if let cgImage = ClipboardService.readCGImage() {
                    let raw = try await OCRService.recognizeText(from: cgImage)
                    return OCRService.clean(raw)
                }
            }
            try await Task.sleep(nanoseconds: 80_000_000) // 80ms
        }

        throw FlowError.timeoutWaitingForClipboard
    }
}

enum ScreencaptureCLI {
    static func runInteractiveCopyToClipboard() async throws {
        // /usr/sbin/screencapture -i -c -t png
        // -i: interactive selection
        // -c: copy image to clipboard
        // -t png: use png
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        proc.arguments = ["-i", "-c", "-t", "png"]

        let err = Pipe()
        proc.standardError = err

        try proc.run()
        proc.waitUntilExit()

        if proc.terminationStatus == 0 {
            return
        }

        // 用户按 ESC 取消时，screencapture 可能返回非 0；
        // 这里用 stderr 做更友好的提示。
        let errData = err.fileHandleForReading.readDataToEndOfFile()
        let errStr = String(data: errData, encoding: .utf8) ?? ""

        // 经验上取消通常就是空 stderr + 非0
        if errStr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ScreenshotOCRFlow.FlowError.screenshotCancelled
        }

        throw ScreenshotOCRFlow.FlowError.screenshotFailed(errStr.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
