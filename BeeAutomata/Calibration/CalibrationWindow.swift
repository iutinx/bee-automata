import AppKit

protocol CalibrationWindowDelegate: AnyObject {
    func calibrationWindow(_ window: CalibrationWindow, didConfirmCircle center: NSPoint)
    func calibrationWindow(_ window: CalibrationWindow, didConfirmRect rect: NSRect)
    func calibrationWindowDidCancel(_ window: CalibrationWindow)
}

final class CalibrationWindow: NSWindow {

    weak var calibrationDelegate: CalibrationWindowDelegate?

    private var instructionLabel: NSTextField!
    private var stepLabel: NSTextField!
    private var confirmButton: NSButton!
    private var mainContentView: CalibrationContentView!

    private var cursorPushed = false

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
        backgroundColor = NSColor.black.withAlphaComponent(0.4)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
        isReleasedWhenClosed = false

        let contentView = NSView(frame: screen)
        self.contentView = contentView

        mainContentView = CalibrationContentView(frame: screen)
        contentView.addSubview(mainContentView)

        setupInstructionBanner()
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
        // Remove all subviews to prevent CoreAnimation from holding stale layer references
        contentView?.subviews.forEach { $0.removeFromSuperview() }
        mainContentView = nil
    }

    func showCircleMode(radius: CGFloat, instruction: String, step: Int, total: Int) {
        let screen = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        mainContentView.circleCenter = NSPoint(x: screen.midX, y: screen.midY)
        mainContentView.mode = .circle(circleRadius: radius)
        mainContentView.needsDisplay = true

        confirmButton.isHidden = false
        instructionLabel.stringValue = instruction
        stepLabel.stringValue = "Step \(step)/\(total) — Press ESC to cancel"
    }

    func showRectangleMode(instruction: String, step: Int, total: Int) {
        mainContentView.selectedRect = nil
        mainContentView.mode = .rectangle
        mainContentView.needsDisplay = true

        confirmButton.isHidden = true
        instructionLabel.stringValue = instruction
        stepLabel.stringValue = "Step \(step)/\(total) — Press ESC to cancel"
    }

    var circleCenter: NSPoint? {
        mainContentView?.circleCenter
    }

    var selectedRect: NSRect? {
        mainContentView?.selectedRect
    }

    private func setupInstructionBanner() {
        let bannerHeight: CGFloat = 90
        let screen = NSScreen.main
        let safeAreaTop = screen?.safeAreaInsets.top ?? 0
        let bannerY = frame.height - bannerHeight - safeAreaTop
        let banner = NSView(frame: NSRect(x: 0, y: bannerY,
                                          width: frame.width, height: bannerHeight))
        banner.wantsLayer = true
        banner.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.8).cgColor
        contentView?.addSubview(banner)

        instructionLabel = NSTextField(labelWithString: "Calibration Mode")
        instructionLabel.frame = NSRect(x: 20, y: 50, width: frame.width - 200, height: 30)
        instructionLabel.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        instructionLabel.textColor = .white
        instructionLabel.alignment = .center
        banner.addSubview(instructionLabel)

        stepLabel = NSTextField(labelWithString: "")
        stepLabel.frame = NSRect(x: 20, y: 25, width: frame.width - 200, height: 20)
        stepLabel.font = NSFont.systemFont(ofSize: 13)
        stepLabel.textColor = NSColor.white.withAlphaComponent(0.7)
        stepLabel.alignment = .center
        banner.addSubview(stepLabel)

        confirmButton = NSButton(title: "Confirm", target: self, action: #selector(confirmClicked))
        confirmButton.frame = NSRect(x: frame.width - 140, y: 30, width: 120, height: 32)
        confirmButton.bezelStyle = .rounded
        confirmButton.keyEquivalent = "\r"
        confirmButton.isHidden = true
        banner.addSubview(confirmButton)
    }

    @objc private func confirmClicked() {
        if let center = circleCenter {
            calibrationDelegate?.calibrationWindow(self, didConfirmCircle: center)
        }
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
