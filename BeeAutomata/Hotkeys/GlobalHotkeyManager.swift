import AppKit

final class GlobalHotkeyManager {

    private var toggleGlobalMonitor: Any?
    private var calibrateGlobalMonitor: Any?
    private var toggleLocalMonitor: Any?
    private var calibrateLocalMonitor: Any?
    private var onToggle: (() -> Void)?
    private var onCalibrate: (() -> Void)?

    private static var instance: GlobalHotkeyManager?

    private static let toggleKeyCode: UInt16 = 46
    private static let calibrateKeyCode: UInt16 = 8
    private static let requiredModifiers: NSEvent.ModifierFlags = [.command, .shift]

    static func register(
        toggleHandler: @escaping () -> Void,
        calibrateHandler: @escaping () -> Void
    ) -> GlobalHotkeyManager {
        let manager = GlobalHotkeyManager()
        manager.onToggle = toggleHandler
        manager.onCalibrate = calibrateHandler
        manager.installMonitors()
        instance = manager
        return manager
    }

    private func installMonitors() {
        toggleGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }

        calibrateGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }

        toggleLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return event
        }

        calibrateLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return event
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard modifiers == Self.requiredModifiers else { return }

        if event.keyCode == Self.toggleKeyCode {
            onToggle?()
        } else if event.keyCode == Self.calibrateKeyCode {
            onCalibrate?()
        }
    }

    deinit {
        if let monitor = toggleGlobalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = calibrateGlobalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = toggleLocalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = calibrateLocalMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
