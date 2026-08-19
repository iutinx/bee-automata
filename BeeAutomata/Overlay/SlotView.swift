import AppKit

enum SlotDisplayState: Equatable {
    case idle, active, inactive
}

final class EditablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class SlotView: NSView {

    private let slotIndex: Int
    private let macroEngine: MacroEngine

    private var displayState: SlotDisplayState = .idle
    private var plusButton: NSButton!
    private var gearButton: NSButton!

    private var assignPanel: NSPanel?
    private var assignTextField: NSTextField?
    private var settingsView: SettingsWheelView?

    init(frame: NSRect, slotIndex: Int, macroEngine: MacroEngine) {
        self.slotIndex = slotIndex
        self.macroEngine = macroEngine
        super.init(frame: frame)
        wantsLayer = true
        setupButtons()
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isFlipped: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let result = super.hitTest(point)
        if result === self { return nil }
        return result
    }

    private func setupButtons() {
        plusButton = NSButton(frame: NSRect(x: bounds.maxX - 18, y: 2, width: 16, height: 16))
        plusButton.title = "+"
        plusButton.bezelStyle = .smallSquare
        plusButton.isBordered = false
        plusButton.wantsLayer = true
        plusButton.layer?.backgroundColor = NSColor.darkGray.withAlphaComponent(0.7).cgColor
        plusButton.layer?.cornerRadius = 3
        plusButton.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        plusButton.contentTintColor = .white
        plusButton.target = self
        plusButton.action = #selector(plusClicked)
        addSubview(plusButton)

        gearButton = NSButton(frame: NSRect(x: bounds.maxX - 18, y: bounds.maxY - 18, width: 16, height: 16))
        gearButton.title = "⚙"
        gearButton.bezelStyle = .smallSquare
        gearButton.isBordered = false
        gearButton.wantsLayer = true
        gearButton.layer?.backgroundColor = NSColor.darkGray.withAlphaComponent(0.7).cgColor
        gearButton.layer?.cornerRadius = 3
        gearButton.font = NSFont.systemFont(ofSize: 11)
        gearButton.contentTintColor = .white
        gearButton.target = self
        gearButton.action = #selector(gearClicked)
        gearButton.isHidden = true
        addSubview(gearButton)
    }

    func updateState(_ config: SlotConfig) {
        let newState: SlotDisplayState
        if !config.assigned {
            newState = .idle
        } else if config.isActive {
            newState = .active
        } else {
            newState = .inactive
        }

        guard newState != displayState else { return }
        displayState = newState
        plusButton.isHidden = config.assigned
        gearButton.isHidden = !config.assigned
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 2, dy: 2)
        let path = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)

        switch displayState {
        case .idle:
            NSColor.gray.withAlphaComponent(0.4).setStroke()
            path.lineWidth = 1.5
            path.stroke()
        case .active:
            NSColor.systemBlue.setStroke()
            path.lineWidth = 3
            path.stroke()
        case .inactive:
            NSColor.systemRed.setStroke()
            path.lineWidth = 3
            path.stroke()
        }
    }

    @objc private func plusClicked() {
        if let panel = assignPanel, panel.isVisible {
            closeAssignDialog()
            return
        }
        showAssignDialog()
    }

    @objc private func gearClicked() {
        if let panel = settingsView?.panel, panel.isVisible {
            closeSettingsPanel()
            return
        }
        showSettingsPanel()
    }

    private func showAssignDialog() {
        closeAssignDialog()
        closeSettingsPanel()

        if let overlayWindow = self.window as? HotbarOverlayWindow {
            overlayWindow.setEventHandlingDisabled(true)
        }

        let panel = makePanel(width: 200, height: 110)

        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 110))
        panel.contentView = contentView

        let bg = makeHUDBackground(width: 200, height: 110)
        contentView.addSubview(bg)

        let label = NSTextField(labelWithString: "Interval (ms):")
        label.frame = NSRect(x: 12, y: 72, width: 176, height: 20)
        label.font = NSFont.systemFont(ofSize: 12)
        contentView.addSubview(label)

        let textField = NSTextField(frame: NSRect(x: 12, y: 44, width: 176, height: 24))
        textField.stringValue = "1000"
        textField.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        textField.isEditable = true
        textField.isSelectable = true
        contentView.addSubview(textField)
        assignTextField = textField

        let okButton = NSButton(title: "Assign", target: self, action: #selector(assignConfirmed))
        okButton.frame = NSRect(x: 12, y: 10, width: 82, height: 26)
        okButton.bezelStyle = .rounded
        okButton.keyEquivalent = "\r"
        contentView.addSubview(okButton)

        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(assignCancelled))
        cancelButton.frame = NSRect(x: 106, y: 10, width: 82, height: 26)
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}"
        contentView.addSubview(cancelButton)

        positionPanel(panel, nearSlot: true)
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(textField)
        assignPanel = panel
    }

    private func closeAssignDialog() {
        assignPanel?.close()
        assignPanel = nil
        assignTextField = nil

        if let overlayWindow = self.window as? HotbarOverlayWindow {
            overlayWindow.setEventHandlingDisabled(false)
        }
    }

    @objc private func assignConfirmed() {
        let interval = max(100, assignTextField?.integerValue ?? 1000)
        macroEngine.configure(slotIndex: slotIndex, intervalMs: interval)
        closeAssignDialog()
    }

    @objc private func assignCancelled() {
        closeAssignDialog()
    }

    private func showSettingsPanel() {
        closeAssignDialog()
        closeSettingsPanel()

        if let overlayWindow = self.window as? HotbarOverlayWindow {
            overlayWindow.setEventHandlingDisabled(true)
        }

        let slot = macroEngine.slots[slotIndex]
        let sv = SettingsWheelView(
            isActive: slot.isActive,
            intervalMs: slot.intervalMs,
            onToggle: { [weak self] active in
                self?.macroEngine.toggleSlotActive(active, slotIndex: self?.slotIndex ?? 0)
            },
            onApply: { [weak self] ms in
                self?.macroEngine.configure(slotIndex: self?.slotIndex ?? 0, intervalMs: ms)
            },
            onUnassign: { [weak self] in
                self?.macroEngine.unassign(slotIndex: self?.slotIndex ?? 0)
            },
            onClose: { [weak self] in
                self?.closeSettingsPanel()
            }
        )

        let panel = makePanel(width: 200, height: 200)
        panel.contentView = sv
        sv.frame = NSRect(x: 0, y: 0, width: 200, height: 200)

        positionPanel(panel, nearSlot: true)
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(sv.intervalField)
        sv.panel = panel
        settingsView = sv
    }

    private func closeSettingsPanel() {
        settingsView?.panel?.close()
        settingsView = nil

        if let overlayWindow = self.window as? HotbarOverlayWindow {
            overlayWindow.setEventHandlingDisabled(false)
        }
    }

    private func makePanel(width: CGFloat, height: CGFloat) -> EditablePanel {
        let panel = EditablePanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = false
        return panel
    }

    private func makeHUDBackground(width: CGFloat, height: CGFloat) -> NSVisualEffectView {
        let bg = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        bg.material = .hudWindow
        bg.state = .active
        bg.wantsLayer = true
        bg.layer?.cornerRadius = 8
        bg.layer?.masksToBounds = true
        return bg
    }

    private func positionPanel(_ panel: NSPanel, nearSlot: Bool) {
        guard let window = self.window else { return }
        let slotRectInWindow = convert(bounds, to: nil)
        let screenPoint = window.convertPoint(toScreen: NSPoint(x: slotRectInWindow.origin.x, y: slotRectInWindow.maxY))
        panel.setFrameOrigin(NSPoint(x: screenPoint.x, y: screenPoint.y + 8))
    }
}
