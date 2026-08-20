import AppKit

final class CalibrationController: CalibrationWindowDelegate {

    private enum CalibrationStep: Equatable {
        case abilityCircle(abilityIndex: Int)
        case boostRegion
        case complete

        var instruction: String {
            switch self {
            case .abilityCircle(let i):
                return "Drag the circle over Ability \(i + 1) counter, then click Confirm"
            case .boostRegion:
                return "Drag to select the Boost Token search area"
            case .complete:
                return "Calibration complete!"
            }
        }

        var stepNumber: Int {
            switch self {
            case .abilityCircle(let i): return i + 1
            case .boostRegion: return 3
            case .complete: return 3
            }
        }

        static let totalSteps = 3
    }

    private var window: CalibrationWindow?
    private var currentStep: CalibrationStep = .abilityCircle(abilityIndex: 0)

    private var abilityCircles: [CalibrationCircle] = []
    private var boostSearchRegion: CalibrationRect?

    private var onComplete: ((CalibrationProfile) -> Void)?

    private let circleRadius: CGFloat = 30

    func start(onComplete: @escaping (CalibrationProfile) -> Void) {
        self.onComplete = onComplete

        abilityCircles = []
        boostSearchRegion = nil
        currentStep = .abilityCircle(abilityIndex: 0)

        let calWindow = CalibrationWindow()
        calWindow.calibrationDelegate = self
        calWindow.makeKeyAndOrderFront(nil)
        window = calWindow

        showCurrentStep()
    }

    func cancel() {
        window?.cleanup()
        window?.orderOut(nil)
        window = nil
    }

    private func showCurrentStep() {
        guard let window = window else { return }

        switch currentStep {
        case .abilityCircle:
            window.showCircleMode(
                radius: circleRadius,
                instruction: currentStep.instruction,
                step: currentStep.stepNumber,
                total: CalibrationStep.totalSteps
            )
        case .boostRegion:
            window.showRectangleMode(
                instruction: currentStep.instruction,
                step: currentStep.stepNumber,
                total: CalibrationStep.totalSteps
            )
        case .complete:
            break
        }
    }

    func calibrationWindow(_ window: CalibrationWindow, didConfirmCircle center: NSPoint) {
        guard case .abilityCircle(let i) = currentStep else { return }

        let circle = CalibrationCircle(center: center, radius: circleRadius)
        abilityCircles.append(circle)

        if i < CalibrationProfile.abilityCount - 1 {
            currentStep = .abilityCircle(abilityIndex: i + 1)
        } else {
            currentStep = .boostRegion
        }

        showCurrentStep()
    }

    func calibrationWindow(_ window: CalibrationWindow, didConfirmRect rect: NSRect) {
        guard case .boostRegion = currentStep else { return }

        boostSearchRegion = CalibrationRect(
            topLeft: CalibrationPoint(x: rect.minX, y: rect.maxY),
            bottomRight: CalibrationPoint(x: rect.maxX, y: rect.minY)
        )
        currentStep = .complete
        finishCalibration()
    }

    func calibrationWindowDidCancel(_ window: CalibrationWindow) {
        print("[Calibration] Cancelled by user")
        cancel()
    }

    private func finishCalibration() {
        guard let boostRegion = boostSearchRegion,
              abilityCircles.count == CalibrationProfile.abilityCount else {
            print("[Calibration] Incomplete data, aborting save")
            cancel()
            return
        }

        let resolution = ProfileManager.shared.currentScreenResolution()
        let profile = CalibrationProfile(
            screenResolution: resolution,
            createdAt: Date(),
            abilityROIs: abilityCircles,
            boostSearchRegion: boostRegion
        )

        ProfileManager.shared.saveProfile(profile)

        window?.cleanup()
        window?.orderOut(nil)
        window = nil

        onComplete?(profile)
        print("[Calibration] Complete — profile saved")
    }
}
