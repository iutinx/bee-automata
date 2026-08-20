import AppKit
import Combine

final class AppState: ObservableObject {

    @Published var macroEngine = MacroEngine()
    @Published var profile: CalibrationProfile

    private var hotkeyManager: GlobalHotkeyManager?
    private var overlayWindow: HotbarOverlayWindow?
    private var calibrationController: CalibrationController?
    private var cancellables = Set<AnyCancellable>()

    init() {
        profile = ProfileManager.shared.loadProfile()
    }

    func initialize() {
        hotkeyManager = GlobalHotkeyManager.register(
            toggleHandler: { [weak self] in
                self?.macroEngine.toggle()
            },
            calibrateHandler: { [weak self] in
                self?.startCalibration()
            }
        )

        let overlay = HotbarOverlayWindow(macroEngine: macroEngine)
        overlay.orderFront(nil)
        overlayWindow = overlay
    }

    func startCalibration() {
        guard calibrationController == nil else { return }
        let controller = CalibrationController()
        calibrationController = controller
        controller.start { [weak self] newProfile in
            self?.profile = newProfile
            self?.calibrationController = nil
        }
    }
}
