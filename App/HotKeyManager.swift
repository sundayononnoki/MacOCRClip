import AppKit
import Carbon

/// 全局快捷键：RegisterEventHotKey
/// - 默认：⌥ + ⇧ + O
final class HotKeyManager: ObservableObject {
    static let shared = HotKeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    private init() {}

    func start() {
        // 避免重复注册
        if hotKeyRef != nil { return }

        // keyCode: kVK_ANSI_O
        let keyCode = UInt32(kVK_ANSI_O)
        let modifiers = UInt32(optionKey | shiftKey)

        var hotKeyID = EventHotKeyID(signature: OSType("MOCR".fourCharCode), id: 1)

        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        // 安装事件回调
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), { (_, event, _) -> OSStatus in
            var hkID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &hkID)

            if hkID.signature == OSType("MOCR".fourCharCode) && hkID.id == 1 {
                Task { @MainActor in
                    SelectionOverlayController.shared.beginSelection()
                }
            }
            return noErr
        }, 1, &eventType, nil, &eventHandler)
    }

    func stop() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }
}

private extension String {
    var fourCharCode: FourCharCode {
        var result: FourCharCode = 0
        for scalar in unicodeScalars.prefix(4) {
            result = (result << 8) + FourCharCode(scalar.value)
        }
        return result
    }
}
