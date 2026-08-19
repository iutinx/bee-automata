import Foundation
import Combine

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
        isRunning = true

        for i in 0..<Self.slotCount {
            guard slots[i].assigned, slots[i].isActive else { continue }
            startTimer(for: i)
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false

        for i in 0..<Self.slotCount {
            stopTimer(for: i)
        }
    }

    func toggle() {
        if isRunning { stop() } else { start() }
    }

    private func startTimer(for index: Int) {
        let interval = TimeInterval(slots[index].intervalMs) / 1000.0
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
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
}
