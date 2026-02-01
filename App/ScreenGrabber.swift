import CoreGraphics

enum ScreenGrabber {
    /// 使用 CGWindowListCreateImage 从全局屏幕坐标 rect 截图。
    /// - 注意：在新版本 macOS 上可能需要“屏幕录制”权限。
    static func capture(rect: CGRect) -> CGImage? {
        // .optionOnScreenOnly：只抓屏幕上内容
        // .bestResolution：尽量高分辨率（对 retina 重要）
        let image = CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution]
        )
        return image
    }
}
