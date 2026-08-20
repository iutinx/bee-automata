import Foundation
import Combine
import AppKit

struct SlotConfig: Codable, Equatable {
    var assigned: Bool = false
    var intervalMs: Int = 1000
    var isActive: Bool = true
}

final class MacroEngine: ObservableObject {

    static let slotCount = 7

    @Published var slots: [SlotConfig] = Array(repeating: SlotConfig(), count: 7)
    @Published private(set) var isRunning = false

    private var timers: [Timer?] = Array(repeating: nil, count: 7)

    func configure(slotIndex: Int, intervalMs: Int) {
        guard slotIndex >= 0, slotIndex < Self.slotCount else { return }
        slots[slotIndex].assigned = true
        slots[slotIndex].intervalMs = max(100, intervalMs)

        if isRunning {
            restartTimer(for: slotIndex)
        }
    }

    func unassign(slotIndex: Int) {
        guard slotIndex >= 0, slotIndex < Self.slotCount else { return }
        slots[slotIndex].assigned = false
        slots[slotIndex].intervalMs = 1000
        slots[slotIndex].isActive = true
        stopTimer(for: slotIndex)
    }

    func toggleSlotActive(_ active: Bool, slotIndex: Int) {
        guard slotIndex >= 0, slotIndex < Self.slotCount else { return }
        slots[slotIndex].isActive = active

        if isRunning {
            if active && slots[slotIndex].assigned {
                restartTimer(for: slotIndex)
            } else {
                stopTimer(for: slotIndex)
            }
        }
    }

    func start() {
        guard !isRunning else { return }
        
        print("[MacroEngine] Starting macro...")
        print("[MacroEngine] Accessibility trusted: \(InputSynthesis.isAccessibilityTrusted())")
        
        if !InputSynthesis.isAccessibilityTrusted() {
            print("[MacroEngine] ERROR: Accessibility permission not granted")
            showAccessibilityAlert()
            return
        }
        
        isRunning = true
        
        var activeTimers = 0
        for i in 0..<Self.slotCount {
            guard slots[i].assigned, slots[i].isActive else { continue }
            print("[MacroEngine] Starting timer for slot \(i) with interval \(slots[i].intervalMs)ms")
            startTimer(for: i)
            activeTimers += 1
        }
        
        print("[MacroEngine] Started \(activeTimers) active timer(s)")
    }

    func stop() {
        guard isRunning else { return }
        print("[MacroEngine] Stopping macro...")
        isRunning = false

        for i in 0..<Self.slotCount {
            stopTimer(for: i)
        }
    }

    func toggle() {
        print("[MacroEngine] Toggle called, current state: \(isRunning ? "running" : "stopped")")
        if isRunning { stop() } else { start() }
    }

    private func startTimer(for index: Int) {
        let interval = TimeInterval(slots[index].intervalMs) / 1000.0
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            print("[MacroEngine] Timer fired for slot \(index)")
            InputSynthesis.pressKey(slotIndex: index)
        }
        RunLoop.main.add(timer, forMode: .common)
        timers[index] = timer
    }

    private func stopTimer(for index: Int) {
        timers[index]?.invalidate()
        timers[index] = nil
    }

    private func restartTimer(for index: Int) {
        stopTimer(for: index)
        guard slots[index].assigned, slots[index].isActive else { return }
        startTimer(for: index)
    }
    
    private func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "Bee Automata needs accessibility permission to simulate key presses.\n\nPlease enable Bee Automata in System Preferences > Privacy & Security > Accessibility."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
