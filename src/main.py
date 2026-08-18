import logging
import sys
import time

from src.hotkeys import HotkeyListener
from src.state import SharedState

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)


def main():
    logger.info("BSS Assist starting — Phase 1: Kill Switch")
    logger.info("F6=pause/resume  F7=debug toggle  F8=kill")

    state = SharedState()
    hotkeys = HotkeyListener(state)
    hotkeys.start()

    try:
        while not state.killed.is_set():
            status = "PAUSED" if state.paused else "RUNNING"
            debug = "DEBUG ON" if state.debug_overlay else "DEBUG OFF"
            print(f"\r[{status}] [{debug}] Waiting for input... ", end="", flush=True)
            state.wait(timeout=1.0)

        print()
        logger.info("Kill signal received. Exiting.")
    except KeyboardInterrupt:
        logger.info("Keyboard interrupt received. Exiting.")
    finally:
        hotkeys.stop()
        logger.info("BSS Assist stopped.")


if __name__ == "__main__":
    main()
