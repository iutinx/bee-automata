import AppKit

final class SettingsWheelView: NSView {

    weak var panel: NSPanel?

    private let onToggle: (Bool) -> Void
    private let onApply: (Int) -> Void
    private let onUnassign: () -> Void
    private let onClose: () -> Void

    private var toggleSwitch: NSSwitch!
    var intervalField: NSTextField!

    init(isActive: Bool, intervalMs: Int, onToggle: @escaping (Bool) -> Void, onApply: @escaping (Int) -> Void, onUnassign: @escaping () -> Void, onClose: @escaping () -> Void) {
        self.onToggle = onToggle
        self.onApply = onApply
        self.onUnassign = onUnassign
        self.onClose = onClose
        super.init(frame: .zero)

        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        layer?.cornerRadius = 8
        layer?.masksToBounds = true

        setupControls(isActive: isActive, intervalMs: intervalMs)
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupControls(isActive: Bool, intervalMs: Int) {
        let activeLabel = NSTextField(labelWithString: "Active:")
        activeLabel.frame = NSRect(x: 12, y: 150, width: 55, height: 20)
        activeLabel.font = NSFont.systemFont(ofSize: 12)
        addSubview(activeLabel)

        toggleSwitch = NSSwitch(frame: NSRect(x: 72, y: 148, width: 40, height: 24))
        toggleSwitch.state = isActive ? .on : .off
        toggleSwitch.target = self
        toggleSwitch.action = #selector(toggleChanged)
        addSubview(toggleSwitch)

        let intervalLabel = NSTextField(labelWithString: "Interval (ms):")
        intervalLabel.frame = NSRect(x: 12, y: 116, width: 176, height: 20)
        intervalLabel.font = NSFont.systemFont(ofSize: 12)
        addSubview(intervalLabel)

        intervalField = NSTextField(frame: NSRect(x: 12, y: 88, width: 176, height: 24))
        intervalField.stringValue = "\(intervalMs)"
        intervalField.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        intervalField.isEditable = true
        intervalField.isSelectable = true
        addSubview(intervalField)

        let unassignButton = NSButton(title: "Unassign", target: self, action: #selector(unassignClicked))
        unassignButton.frame = NSRect(x: 12, y: 50, width: 176, height: 26)
        unassignButton.bezelStyle = .rounded
        unassignButton.contentTintColor = .systemRed
        addSubview(unassignButton)

        let applyButton = NSButton(title: "Apply", target: self, action: #selector(applyClicked))
        applyButton.frame = NSRect(x: 12, y: 10, width: 82, height: 26)
        applyButton.bezelStyle = .rounded
        applyButton.keyEquivalent = "\r"
        addSubview(applyButton)

        let closeButton = NSButton(title: "Close", target: self, action: #selector(closeClicked))
        closeButton.frame = NSRect(x: 106, y: 10, width: 82, height: 26)
        closeButton.bezelStyle = .rounded
        closeButton.keyEquivalent = "\u{1b}"
        addSubview(closeButton)
    }

    @objc private func toggleChanged() {
        onToggle(toggleSwitch.state == .on)
    }

    @objc private func applyClicked() {
        let ms = max(100, intervalField.integerValue)
        onApply(ms)
        onClose()
    }

    @objc private func unassignClicked() {
        onUnassign()
        onClose()
    }

    @objc private func closeClicked() {
        onClose()
    }
}
