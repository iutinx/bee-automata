import AppKit
import Combine

final class AppState: ObservableObject {

    @Published var macroEngine = MacroEngine()

    private var hotkeyManager: GlobalHotkeyManager?
    private var overlayWindow: HotbarOverlayWindow?
    private var cancellables = Set<AnyCancellable>()

    func initialize() {
        hotkeyManager = GlobalHotkeyManager.register { [weak self] in
            self?.macroEngine.toggle()
        }

        let overlay = HotbarOverlayWindow(macroEngine: macroEngine)
        overlay.orderFront(nil)
        overlayWindow = overlay
    }
}
