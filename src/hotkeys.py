import logging
import threading
from typing import Callable, Optional

from pynput import keyboard

from src.state import SharedState

logger = logging.getLogger(__name__)


class HotkeyListener:
    def __init__(
        self,
        state: SharedState,
        start_callback: Optional[Callable] = None,
        stop_callback: Optional[Callable] = None,
    ):
        self.state = state
        self._start_callback = start_callback
        self._stop_callback = stop_callback
        self._listener = None

    def start(self):
        self._listener = keyboard.GlobalHotKeys(
            {
                "<f9>": self._on_start,
                "<f6>": self._on_pause,
                "<f10>": self._on_stop,
                "<f8>": self._on_kill,
            }
        )
        self._listener.start()
        logger.info("Hotkey listener started (F9=start, F6=pause, F10=stop, F8=kill)")

    def stop(self):
        if self._listener:
            self._listener.stop()

    def _on_start(self):
        logger.info("Hotkey: START")
        print("[HOTKEY] START")
        if self._start_callback:
            self._start_callback()

    def _on_pause(self):
        new_state = self.state.toggle_paused()
        status = "PAUSED" if new_state else "RESUMED"
        logger.info(f"Hotkey: {status}")
        print(f"[HOTKEY] {status}")

    def _on_stop(self):
        logger.info("Hotkey: STOP")
        print("[HOTKEY] STOP")
        if self._stop_callback:
            self._stop_callback()

    def _on_kill(self):
        logger.info("Hotkey: KILL activated")
        print("[HOTKEY] KILL — shutting down immediately")
        self.state.kill()
