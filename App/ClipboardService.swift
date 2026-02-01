import AppKit
import CoreGraphics

enum ClipboardService {
    static func writeText(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    /// 从剪贴板读取图片（优先 NSImage，再转 CGImage）
    static func readCGImage() -> CGImage? {
        let pb = NSPasteboard.general
        if let data = pb.data(forType: .tiff), let nsImage = NSImage(data: data) {
            return nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        }
        // 兼容 png
        if let data = pb.data(forType: .png), let nsImage = NSImage(data: data) {
            return nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        }
        return nil
    }
}
