import AppKit
import Combine

enum HotbarLayout {
    static let slotSize = NSSize(width: 60, height: 60)
    static let slotGap: CGFloat = 8
    static let slotCount = 7
    static let padding: CGFloat = 10

    static var totalWidth: CGFloat {
        CGFloat(slotCount) * slotSize.width + CGFloat(slotCount - 1) * slotGap + padding * 2
    }

    static var windowSize: NSSize {
        NSSize(width: totalWidth, height: slotSize.height + padding * 2)
    }
}

final class OverlayContentView: NSView {
    override var isFlipped: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let result = super.hitTest(point)
        if result === self { return nil }
        return result
    }
}

final class HotbarOverlayWindow: NSWindow {

    private let macroEngine: MacroEngine
    private var slotViews: [SlotView] = []
    private var cancellables = Set<AnyCancellable>()
    private var isEventHandlingDisabled = false

    init(macroEngine: MacroEngine) {
        self.macroEngine = macroEngine

        let size = HotbarLayout.windowSize
        let screen = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        let origin = NSPoint(
            x: screen.midX - size.width / 2,
            y: 120
        )

        super.init(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        level = .floating
        isOpaque = false
        hasShadow = false
        backgroundColor = .clear
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        ignoresMouseEvents = false

        let contentView = OverlayContentView(frame: NSRect(origin: .zero, size: size))
        self.contentView = contentView

        setupSlotViews()
        observeMacroEngine()
    }

    func setEventHandlingDisabled(_ disabled: Bool) {
        isEventHandlingDisabled = disabled
        if disabled {
            ignoresMouseEvents = true
        } else {
            ignoresMouseEvents = false
        }
    }

    override func sendEvent(_ event: NSEvent) {
        if isEventHandlingDisabled {
            return
        }
        super.sendEvent(event)
    }

    private func setupSlotViews() {
        for i in 0..<HotbarLayout.slotCount {
            let x = HotbarLayout.padding + CGFloat(i) * (HotbarLayout.slotSize.width + HotbarLayout.slotGap)
            let frame = NSRect(
                x: x, y: HotbarLayout.padding,
                width: HotbarLayout.slotSize.width,
                height: HotbarLayout.slotSize.height
            )
            let slotView = SlotView(frame: frame, slotIndex: i, macroEngine: macroEngine)
            contentView?.addSubview(slotView)
            slotViews.append(slotView)
        }
    }

    private func observeMacroEngine() {
        macroEngine.$slots
            .receive(on: RunLoop.main)
            .sink { [weak self] slots in
                guard let self = self else { return }
                for (i, slot) in slots.enumerated() {
                    if i < self.slotViews.count {
                        self.slotViews[i].updateState(slot)
                    }
                }
            }
            .store(in: &cancellables)
    }
}
