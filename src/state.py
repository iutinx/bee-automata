import threading


class SharedState:
    def __init__(self):
        self._killed = threading.Event()
        self._paused = False
        self._lock = threading.Lock()
        self._debug_overlay = False

    @property
    def killed(self):
        return self._killed

    @property
    def paused(self):
        with self._lock:
            return self._paused

    @paused.setter
    def paused(self, value: bool):
        with self._lock:
            self._paused = value

    def toggle_paused(self):
        with self._lock:
            self._paused = not self._paused
            return self._paused

    @property
    def debug_overlay(self):
        with self._lock:
            return self._debug_overlay

    @debug_overlay.setter
    def debug_overlay(self, value: bool):
        with self._lock:
            self._debug_overlay = value

    def toggle_debug_overlay(self):
        with self._lock:
            self._debug_overlay = not self._debug_overlay
            return self._debug_overlay

    def kill(self):
        self._killed.set()

    def wait(self, timeout: float) -> bool:
        return self._killed.wait(timeout)
