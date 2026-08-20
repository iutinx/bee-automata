import AppKit

protocol CalibrationWindowDelegate: AnyObject {
    func calibrationWindow(_ window: CalibrationWindow, didConfirmCircle center: NSPoint)
    func calibrationWindow(_ window: CalibrationWindow, didConfirmRect rect: NSRect)
    func calibrationWindowDidCancel(_ window: CalibrationWindow)
}

final class CalibrationWindow: NSWindow {

    weak var calibrationDelegate: CalibrationWindowDelegate?

    private var hudPanel: NSVisualEffectView!
    private var iconView: NSImageView!
    private var titleLabel: NSTextField!
    private var instructionLabel: NSTextField!
    private var stepDotsView: NSView!
    private var progressIndicator: NSProgressIndicator!
    private var cancelButton: NSButton!
    private var confirmButton: NSButton!
    private var mainContentView: CalibrationContentView!

    private var cursorPushed = false
    private var currentStep = 1
    private var totalSteps = 3

    init() {
        let screen = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)

        super.init(
            contentRect: screen,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        level = .screenSaver
        isOpaque = false
        hasShadow = false
        backgroundColor = NSColor.black.withAlphaComponent(0.3)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
        isReleasedWhenClosed = false

        let contentView = NSView(frame: screen)
        self.contentView = contentView

        mainContentView = CalibrationContentView(frame: screen)
        contentView.addSubview(mainContentView)

        setupHUDPanel()
        NSCursor.crosshair.push()
        cursorPushed = true
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    func cleanup() {
        if cursorPushed {
            NSCursor.pop()
            cursorPushed = false
        }
        contentView?.subviews.forEach { $0.removeFromSuperview() }
        mainContentView = nil
    }

    func showCircleMode(radius: CGFloat, instruction: String, step: Int, total: Int) {
        let screen = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        mainContentView.circleCenter = NSPoint(x: screen.midX, y: screen.midY)
        mainContentView.mode = .circle(circleRadius: radius)
        mainContentView.needsDisplay = true

        currentStep = step
        totalSteps = total
        updateHUD(
            icon: "circle.dashed",
            title: "Circle Calibration",
            instruction: instruction,
            showConfirm: true
        )
    }

    func showRectangleMode(instruction: String, step: Int, total: Int) {
        mainContentView.selectedRect = nil
        mainContentView.mode = .rectangle
        mainContentView.needsDisplay = true

        currentStep = step
        totalSteps = total
        updateHUD(
            icon: "rectangle.dashed",
            title: "Rectangle Selection",
            instruction: instruction,
            showConfirm: false
        )
    }

    var circleCenter: NSPoint? {
        mainContentView?.circleCenter
    }

    var selectedRect: NSRect? {
        mainContentView?.selectedRect
    }

    private func setupHUDPanel() {
        let screen = NSScreen.main
        let safeAreaTop = screen?.safeAreaInsets.top ?? 0
        
        let panelWidth: CGFloat = 480
        let panelHeight: CGFloat = 200
        let panelX = (frame.width - panelWidth) / 2
        let panelY = frame.height - panelHeight - safeAreaTop - 40

        hudPanel = NSVisualEffectView(frame: NSRect(x: panelX, y: panelY, width: panelWidth, height: panelHeight))
        hudPanel.material = .hudWindow
        hudPanel.state = .active
        hudPanel.blendingMode = .behindWindow
        hudPanel.wantsLayer = true
        hudPanel.layer?.cornerRadius = 12
        hudPanel.layer?.masksToBounds = true
        hudPanel.layer?.borderWidth = 1
        hudPanel.layer?.borderColor = NSColor.white.withAlphaComponent(0.1).cgColor
        contentView?.addSubview(hudPanel)

        let contentPadding: CGFloat = 20
        var yOffset = panelHeight - contentPadding

        iconView = NSImageView(frame: NSRect(x: contentPadding, y: yOffset - 32, width: 32, height: 32))
        hudPanel.addSubview(iconView)

        titleLabel = NSTextField(labelWithString: "")
        titleLabel.frame = NSRect(x: contentPadding + 44, y: yOffset - 24, width: panelWidth - 88, height: 24)
        titleLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .labelColor
        titleLabel.alignment = .left
        hudPanel.addSubview(titleLabel)

        yOffset -= 40

        instructionLabel = NSTextField(labelWithString: "")
        instructionLabel.frame = NSRect(x: contentPadding, y: yOffset - 40, width: panelWidth - contentPadding * 2, height: 40)
        instructionLabel.font = NSFont.systemFont(ofSize: 13)
        instructionLabel.textColor = .secondaryLabelColor
        instructionLabel.alignment = .left
        instructionLabel.maximumNumberOfLines = 2
        instructionLabel.lineBreakMode = .byWordWrapping
        hudPanel.addSubview(instructionLabel)

        yOffset -= 50

        stepDotsView = NSView(frame: NSRect(x: contentPadding, y: yOffset - 12, width: 100, height: 12))
        hudPanel.addSubview(stepDotsView)
        setupStepDots()

        progressIndicator = NSProgressIndicator(frame: NSRect(x: contentPadding + 120, y: yOffset - 12, width: panelWidth - 160, height: 12))
        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = false
        progressIndicator.minValue = 0
        progressIndicator.maxValue = 1
        progressIndicator.doubleValue = 0
        hudPanel.addSubview(progressIndicator)

        yOffset -= 30

        let buttonY = yOffset - 28
        cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelClicked))
        cancelButton.frame = NSRect(x: contentPadding, y: buttonY, width: 80, height: 28)
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}"
        hudPanel.addSubview(cancelButton)

        confirmButton = NSButton(title: "Confirm", target: self, action: #selector(confirmClicked))
        confirmButton.frame = NSRect(x: panelWidth - contentPadding - 100, y: buttonY, width: 100, height: 28)
        confirmButton.bezelStyle = .rounded
        confirmButton.keyEquivalent = "\r"
        confirmButton.isHidden = true
        hudPanel.addSubview(confirmButton)
    }

    private func setupStepDots() {
        let dotSize: CGFloat = 8
        let dotSpacing: CGFloat = 8
        
        for i in 0..<totalSteps {
            let dot = StepDotView(frame: NSRect(x: CGFloat(i) * (dotSize + dotSpacing), y: 2, width: dotSize, height: dotSize), index: i)
            dot.wantsLayer = true
            dot.layer?.cornerRadius = dotSize / 2
            dot.layer?.backgroundColor = NSColor.secondaryLabelColor.cgColor
            stepDotsView.addSubview(dot)
        }
    }

    private func updateStepDots() {
        for subview in stepDotsView.subviews {
            if let dot = subview as? StepDotView {
                let isCompleted = dot.index < currentStep
                dot.layer?.backgroundColor = isCompleted
                    ? NSColor.controlAccentColor.cgColor
                    : NSColor.secondaryLabelColor.cgColor
            }
        }
    }

    private func updateHUD(icon: String, title: String, instruction: String, showConfirm: Bool) {
        if let symbolImage = NSImage(systemSymbolName: icon, accessibilityDescription: nil) {
            iconView.image = symbolImage
            iconView.contentTintColor = .controlAccentColor
        }

        titleLabel.stringValue = title
        instructionLabel.stringValue = instruction
        confirmButton.isHidden = !showConfirm

        progressIndicator.doubleValue = Double(currentStep - 1) / Double(totalSteps)
        updateStepDots()
    }

    @objc private func confirmClicked() {
        if let center = circleCenter {
            calibrationDelegate?.calibrationWindow(self, didConfirmCircle: center)
        }
    }

    @objc private func cancelClicked() {
        calibrationDelegate?.calibrationWindowDidCancel(self)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            calibrationDelegate?.calibrationWindowDidCancel(self)
        }
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown {
            keyDown(with: event)
        } else if event.type == .leftMouseUp {
            if let rect = mainContentView?.handleMouseUp(at: event.locationInWindow) {
                calibrationDelegate?.calibrationWindow(self, didConfirmRect: rect)
            }
        } else {
            super.sendEvent(event)
        }
    }
}

final class StepDotView: NSView {
    let index: Int
    
    init(frame: NSRect, index: Int) {
        self.index = index
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class CalibrationContentView: NSView {

    enum Mode {
        case circle(circleRadius: CGFloat)
        case rectangle
    }

    var mode: Mode = .circle(circleRadius: 30)
    var circleCenter: NSPoint = .zero
    var selectedRect: NSRect?

    private var isDragging = false
    private var dragOffset: NSPoint = .zero
    private var rectStartPoint: NSPoint?
    private var currentDragRect: NSRect?

    override var isFlipped: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        switch mode {
        case .circle(let radius):
            drawCircle(radius: radius)
        case .rectangle:
            drawRectangle()
        }
    }

    private func drawCircle(radius: CGFloat) {
        let circleRect = NSRect(
            x: circleCenter.x - radius,
            y: circleCenter.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        let path = NSBezierPath(ovalIn: circleRect)
        NSColor.systemYellow.withAlphaComponent(0.3).setFill()
        path.fill()
        NSColor.systemYellow.setStroke()
        path.lineWidth = 2
        path.stroke()

        let crosshairSize: CGFloat = 10
        let hLine = NSBezierPath()
        hLine.move(to: NSPoint(x: circleCenter.x - crosshairSize, y: circleCenter.y))
        hLine.line(to: NSPoint(x: circleCenter.x + crosshairSize, y: circleCenter.y))
        let vLine = NSBezierPath()
        vLine.move(to: NSPoint(x: circleCenter.x, y: circleCenter.y - crosshairSize))
        vLine.line(to: NSPoint(x: circleCenter.x, y: circleCenter.y + crosshairSize))
        NSColor.systemYellow.setStroke()
        hLine.lineWidth = 1
        hLine.stroke()
        vLine.lineWidth = 1
        vLine.stroke()
    }

    private func drawRectangle() {
        if let rect = currentDragRect ?? selectedRect {
            let path = NSBezierPath(rect: rect)
            NSColor.systemBlue.withAlphaComponent(0.2).setFill()
            path.fill()
            NSColor.systemBlue.setStroke()
            path.lineWidth = 2
            path.stroke()
        }
    }

    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)

        switch mode {
        case .circle(let radius):
            let dx = abs(location.x - circleCenter.x)
            let dy = abs(location.y - circleCenter.y)
            if dx <= radius && dy <= radius {
                isDragging = true
                dragOffset = NSPoint(x: location.x - circleCenter.x, y: location.y - circleCenter.y)
            }
        case .rectangle:
            rectStartPoint = location
            currentDragRect = nil
            selectedRect = nil
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)

        switch mode {
        case .circle:
            if isDragging {
                circleCenter = NSPoint(
                    x: location.x - dragOffset.x,
                    y: location.y - dragOffset.y
                )
                needsDisplay = true
            }
        case .rectangle:
            if let start = rectStartPoint {
                currentDragRect = NSRect(
                    x: min(start.x, location.x),
                    y: min(start.y, location.y),
                    width: abs(location.x - start.x),
                    height: abs(location.y - start.y)
                )
                needsDisplay = true
            }
        }
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false
        rectStartPoint = nil
    }

    func handleMouseUp(at windowPoint: NSPoint) -> NSRect? {
        guard case .rectangle = mode else { return nil }
        guard let rect = currentDragRect, rect.width > 10, rect.height > 10 else {
            currentDragRect = nil
            needsDisplay = true
            return nil
        }
        selectedRect = rect
        currentDragRect = nil
        return rect
    }
}
