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
    private var onFinish: (() -> Void)?

    private let circleRadius: CGFloat = 30

    func start(onComplete: @escaping (CalibrationProfile) -> Void, onFinish: @escaping () -> Void) {
        self.onComplete = onComplete
        self.onFinish = onFinish

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
        onFinish?()
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

    private func lowerWindowLevel() {
        window?.level = .normal
    }

    private func restoreWindowLevel() {
        window?.level = .screenSaver
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
        showCancelConfirmation()
    }

    private func showCancelConfirmation() {
        lowerWindowLevel()
        
        let alert = NSAlert()
        alert.messageText = "Cancel Calibration?"
        alert.informativeText = "All progress will be lost. Are you sure you want to cancel?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Cancel Calibration")
        alert.addButton(withTitle: "Continue")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            print("[Calibration] Cancelled by user")
            cancel()
        } else {
            restoreWindowLevel()
        }
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

        showCompletionConfirmation(profile: profile)
    }

    private func showCompletionConfirmation(profile: CalibrationProfile) {
        lowerWindowLevel()
        
        let alert = NSAlert()
        alert.messageText = "Calibration Complete"
        alert.informativeText = "All calibration data has been collected. Save profile and continue?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Save Profile")
        alert.addButton(withTitle: "Discard")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            ProfileManager.shared.saveProfile(profile)
            
            window?.cleanup()
            window?.orderOut(nil)
            window = nil
            
            onComplete?(profile)
            onFinish?()
            print("[Calibration] Complete — profile saved")
        } else {
            print("[Calibration] Profile discarded by user")
            cancel()
        }
    }
}
