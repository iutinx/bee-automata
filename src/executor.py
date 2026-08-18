import logging
import threading
import time
from typing import Optional

from pynput import keyboard

from src.state import SharedState

logger = logging.getLogger(__name__)

_KEY_MAP = {
    "1": keyboard.KeyCode.from_char("1"),
    "2": keyboard.KeyCode.from_char("2"),
    "3": keyboard.KeyCode.from_char("3"),
    "4": keyboard.KeyCode.from_char("4"),
    "5": keyboard.KeyCode.from_char("5"),
    "6": keyboard.KeyCode.from_char("6"),
    "7": keyboard.KeyCode.from_char("7"),
    "8": keyboard.KeyCode.from_char("8"),
    "9": keyboard.KeyCode.from_char("9"),
    "0": keyboard.KeyCode.from_char("0"),
}

_controller = keyboard.Controller()


def _press_key(slot_number: str):
    key = _KEY_MAP.get(slot_number)
    if key is None:
        logger.warning(f"Unknown slot number: {slot_number}")
        return
    _controller.press(key)
    _controller.release(key)
    logger.debug(f"Pressed key: {slot_number}")


class ParallelExecutor:
    def __init__(self, state: SharedState):
        self.state = state
        self._thread: Optional[threading.Thread] = None
        self._active_slots: dict = {}
        self._next_fire_times: dict = {}
        self._lock = threading.Lock()
        self._press_counts: dict = {}

    def start(self, hotbar_config: dict):
        with self._lock:
            self._active_slots = {}
            self._next_fire_times = {}
            self._press_counts = {}

            for slot, config in hotbar_config.items():
                interval_ms = config.get("interval_ms", 0)
                if interval_ms > 0:
                    self._active_slots[slot] = config
                    self._next_fire_times[slot] = time.monotonic() + (interval_ms / 1000.0)
                    self._press_counts[slot] = 0

        if self._thread and self._thread.is_alive():
            logger.warning("Executor already running")
            return

        self.state.killed.clear()
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()
        logger.info(f"Parallel executor started with {len(self._active_slots)} active slots")

    def stop(self):
        self.state.kill()
        if self._thread:
            self._thread.join(timeout=2.0)

    @property
    def is_running(self) -> bool:
        return self._thread is not None and self._thread.is_alive()

    @property
    def active_slot_count(self) -> int:
        with self._lock:
            return len(self._active_slots)

    def get_time_remaining(self, slot: str) -> Optional[float]:
        with self._lock:
            if slot not in self._next_fire_times:
                return None
            remaining = self._next_fire_times[slot] - time.monotonic()
            return max(0.0, remaining)

    def get_press_count(self, slot: str) -> int:
        with self._lock:
            return self._press_counts.get(slot, 0)

    def _run(self):
        while not self.state.killed.is_set():
            if self.state.paused:
                time.sleep(0.05)
                continue

            with self._lock:
                if not self._active_slots:
                    logger.info("No active slots, stopping")
                    break

                now = time.monotonic()
                earliest_slot = None
                earliest_time = float("inf")

                for slot, fire_time in self._next_fire_times.items():
                    if fire_time < earliest_time:
                        earliest_time = fire_time
                        earliest_slot = slot

            if earliest_slot is None:
                break

            sleep_time = earliest_time - now
            if sleep_time > 0:
                self.state.wait(sleep_time)
                if self.state.killed.is_set():
                    break
                while self.state.paused:
                    if self.state.killed.is_set():
                        return
                    time.sleep(0.05)

            if self.state.killed.is_set():
                break

            with self._lock:
                config = self._active_slots.get(earliest_slot)
                if config is None:
                    continue

                interval_ms = config.get("interval_ms", 0)
                self._next_fire_times[earliest_slot] = time.monotonic() + (interval_ms / 1000.0)
                self._press_counts[earliest_slot] = self._press_counts.get(earliest_slot, 0) + 1

            _press_key(earliest_slot)
            logger.info(f"Slot {earliest_slot}: pressed '{config.get('item', '')}'")
