import Carbon
import AppKit

final class GlobalHotkeyManager {

    private var hotkeyRef: EventHotKeyRef?
    private var onToggle: (() -> Void)?

    private static var instance: GlobalHotkeyManager?

    static func register(toggleHandler: @escaping () -> Void) -> GlobalHotkeyManager {
        let manager = GlobalHotkeyManager()
        manager.onToggle = toggleHandler
        manager.installHandler()
        instance = manager
        return manager
    }

    private func installHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return noErr }
                let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.onToggle?()
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            nil
        )

        let hotkeyID = EventHotKeyID(signature: 0x42534153, id: 1)
        RegisterEventHotKey(
            UInt32(kVK_F6),
            UInt32(0),
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )
    }

    deinit {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
        }
    }
}
