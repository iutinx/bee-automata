import logging
import threading

from pynput import keyboard

from src.state import SharedState

logger = logging.getLogger(__name__)


class HotkeyListener:
    def __init__(self, state: SharedState):
        self.state = state
        self._listener = None

    def start(self):
        self._listener = keyboard.GlobalHotKeys(
            {
                "<f6>": self._on_pause,
                "<f7>": self._on_debug_toggle,
                "<f8>": self._on_kill,
            }
        )
        self._listener.start()
        logger.info("Hotkey listener started (F6=pause, F7=debug, F8=kill)")

    def stop(self):
        if self._listener:
            self._listener.stop()

    def _on_pause(self):
        new_state = self.state.toggle_paused()
        status = "PAUSED" if new_state else "RESUMED"
        logger.info(f"Hotkey: {status}")
        print(f"[HOTKEY] {status}")

    def _on_debug_toggle(self):
        new_state = self.state.toggle_debug_overlay()
        status = "DEBUG ON" if new_state else "DEBUG OFF"
        logger.info(f"Hotkey: {status}")
        print(f"[HOTKEY] {status}")

    def _on_kill(self):
        logger.info("Hotkey: KILL activated")
        print("[HOTKEY] KILL — shutting down immediately")
        self.state.kill()
