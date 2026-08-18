import CoreGraphics
import Carbon.HIToolbox

enum InputSynthesis {

    static let hotbarKeyCodes: [CGKeyCode] = [
        CGKeyCode(kVK_ANSI_1),
        CGKeyCode(kVK_ANSI_2),
        CGKeyCode(kVK_ANSI_3),
        CGKeyCode(kVK_ANSI_4),
        CGKeyCode(kVK_ANSI_5),
        CGKeyCode(kVK_ANSI_6),
        CGKeyCode(kVK_ANSI_7),
    ]

    static func pressKey(slotIndex: Int) {
        guard slotIndex >= 0, slotIndex < hotbarKeyCodes.count else { return }
        let keyCode = hotbarKeyCodes[slotIndex]

        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        else { return }

        keyDown.post(tap: CGEventTapLocation.cghidEventTap)
        keyUp.post(tap: CGEventTapLocation.cghidEventTap)
    }
}
