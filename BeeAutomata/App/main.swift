import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    let appState = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        appState.initialize()
        print("[Bee Automata] Running. Press F6 to toggle macro.")
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState.macroEngine.stop()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
