import logging

logger = logging.getLogger(__name__)

try:
    from AppKit import NSApp, NSColor, NSScreen, NSWindow
    HAS_PYOBJC = True
except ImportError:
    HAS_PYOBJC = False
    logger.warning("pyobjc not available — native features disabled")


def get_root_ns_window():
    if not HAS_PYOBJC:
        return None
    try:
        app = NSApp
        if app is None:
            return None
        for window in app.windows():
            if window.isVisible():
                return window
    except Exception:
        pass
    return None


def set_transparent_background():
    if not HAS_PYOBJC:
        return
    try:
        window = get_root_ns_window()
        if window is None:
            logger.debug("No window found for transparent background")
            return
        window.setBackgroundColor_(NSColor.clearColor())
        window.setOpaque_(False)
        window.setHasShadow_(False)
        logger.info("Transparent background set")
    except Exception as e:
        logger.debug(f"Error setting transparent background: {e}")


def get_screen_size():
    if not HAS_PYOBJC:
        return (1920, 1080)
    try:
        screen = NSScreen.mainScreen()
        frame = screen.frame()
        return (int(frame.size.width), int(frame.size.height))
    except Exception:
        return (1920, 1080)


def position_viewport(x: float, y: float):
    if not HAS_PYOBJC:
        return
    try:
        window = get_root_ns_window()
        if window is None:
            return
        from AppKit import NSPoint, NSSize
        window.setFrameOrigin_(NSPoint(x, y))
        logger.info(f"Viewport positioned at ({x}, {y})")
    except Exception as e:
        logger.debug(f"Error positioning viewport: {e}")


def set_click_through(enabled: bool):
    if not HAS_PYOBJC:
        return
    try:
        window = get_root_ns_window()
        if window is None:
            return
        window.setIgnoresMouseEvents_(enabled)
    except Exception:
        pass


def set_window_level(level: int):
    if not HAS_PYOBJC:
        return
    try:
        window = get_root_ns_window()
        if window is None:
            return
        window.setLevel_(level)
    except Exception:
        pass


NSFLOATING_WINDOW_LEVEL = 3
