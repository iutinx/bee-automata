import AppKit
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate {

    let appState = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        checkAccessibilityPermission()
        appState.initialize()
        print("[Bee Automata] Running. Cmd+Shift+M = toggle macro, Cmd+Shift+C = calibrate.")
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState.macroEngine.stop()
    }
    
    private func checkAccessibilityPermission() {
        if !AXIsProcessTrusted() {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "Bee Automata needs accessibility permission to simulate key presses.\n\nPlease enable Bee Automata in System Preferences > Privacy & Security > Accessibility."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Continue Anyway")
            
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
