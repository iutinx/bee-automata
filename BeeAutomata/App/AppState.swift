import Foundation
import Combine

final class AppState: ObservableObject {

    @Published var macroEngine = MacroEngine()

    private var hotkeyManager: GlobalHotkeyManager?
    private var cancellables = Set<AnyCancellable>()

    func initialize() {
        hotkeyManager = GlobalHotkeyManager.register { [weak self] in
            self?.macroEngine.toggle()
        }
    }
}
