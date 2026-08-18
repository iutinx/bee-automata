import logging

import dearpygui.dearpygui as dpg

from src.executor import ParallelExecutor
from src.gui.icons import GLOW_SIZE, SlotIcons, draw_slot_tile, update_tile_state, update_tile_count
from src.gui.native import (
    get_screen_size,
    position_viewport,
    set_click_through,
    set_transparent_background,
)
from src.gui.popover import SettingsPopover
from src.gui.theme import (
    GREEN,
    RED,
    TEXT_DIM,
    YELLOW,
    build_theme,
    register_fonts,
)
from src.hotkeys import HotkeyListener
from src.items import BSS_ITEMS, DEFAULT_HOTBAR
from src.state import SharedState

logger = logging.getLogger(__name__)

TILE_SIZE = 64
TILE_GAP = 4
NUM_SLOTS = 7
TILE_ROW_HEIGHT = GLOW_SIZE

VIEWPORT_WIDTH = (TILE_SIZE * NUM_SLOTS) + (TILE_GAP * (NUM_SLOTS - 1)) + 16
VIEWPORT_HEIGHT = TILE_ROW_HEIGHT + 16


class BSSAssistApp:
    def __init__(self):
        self.app_state = SharedState()
        self.slot_icons = SlotIcons()
        self.popover = None

        self.hotbar: dict = {}
        self.slot_states: dict = {}
        self.slot_tags: dict = {}

        for slot_num in range(1, NUM_SLOTS + 1):
            slot_key = str(slot_num)
            self.hotbar[slot_key] = {
                "item": DEFAULT_HOTBAR.get(slot_key, ""),
                "interval_ms": 0,
                "enabled": False,
            }
            self.slot_states[slot_key] = "off"

        self.executor = ParallelExecutor(self.app_state)
        self.hotkeys = HotkeyListener(
            self.app_state,
            start_callback=self._start,
            stop_callback=self._stop,
        )

    def run(self):
        dpg.create_context()
        register_fonts()
        build_theme()

        self._build_ui()
        self.popover = SettingsPopover(self)
        self._build_file_dialogs()

        dpg.create_viewport(
            title="Bee Automata",
            width=VIEWPORT_WIDTH,
            height=VIEWPORT_HEIGHT,
            min_width=VIEWPORT_WIDTH,
            min_height=VIEWPORT_HEIGHT,
            max_width=VIEWPORT_WIDTH,
            max_height=VIEWPORT_HEIGHT,
            always_on_top=True,
            decorated=False,
            clear_color=(0, 0, 0, 0),
        )
        dpg.setup_dearpygui()
        dpg.show_viewport()

        set_transparent_background()
        self._position_overlay()

        self.hotkeys.start()

        while dpg.is_dearpygui_running():
            dpg.render_dearpygui_frame()

            if self.app_state.killed.is_set():
                break

            self._poll_status()

        self._cleanup()
        dpg.destroy_context()

    def _position_overlay(self):
        screen_w, screen_h = get_screen_size()
        x = (screen_w - VIEWPORT_WIDTH) / 2
        y = screen_h * 0.3
        position_viewport(x, y)
        logger.info(f"Overlay positioned at ({x:.0f}, {y:.0f}) on {screen_w}x{screen_h} screen")

    def _build_ui(self):
        with dpg.window(
            label="Bee Automata",
            tag="main_window",
            no_title_bar=True,
            no_move=True,
            no_resize=True,
            no_collapse=True,
            no_background=True,
        ):
            dpg.set_primary_window("main_window", True)
            dpg.bind_item_theme("main_window", "transparent_window_theme")
            self._build_tile_row()

    def _build_tile_row(self):
        window_container = dpg.last_container()
        with dpg.group(horizontal=True, parent=window_container, tag="tile_row_group"):
            group_container = dpg.last_container()
            for slot_num in range(1, NUM_SLOTS + 1):
                slot_key = str(slot_num)
                state = self.slot_states[slot_key]
                quantity = self.slot_icons.get_quantity(slot_key)

                tags = draw_slot_tile(
                    group_container,
                    slot_key,
                    f"slot_tile_{slot_key}",
                    state=state,
                    quantity=quantity,
                )
                self.slot_tags[slot_key] = tags

                if slot_num < NUM_SLOTS:
                    dpg.add_spacer(width=TILE_GAP)

    def _build_file_dialogs(self):
        with dpg.file_dialog(
            directory_selector=False,
            show=False,
            callback=self.popover.on_image_selected,
            cancel_callback=lambda: None,
            width=500,
            height=400,
            tag="popover_image_dialog",
        ):
            dpg.add_file_extension(".png")
            dpg.add_file_extension(".jpg")
            dpg.add_file_extension(".jpeg")

    def _on_tile_left_click(self, slot_key: str):
        current_state = self.slot_states[slot_key]
        new_state = "active" if current_state == "off" else "off"
        self.slot_states[slot_key] = new_state
        update_tile_state(self.slot_tags[slot_key], new_state)
        logger.info(f"Slot {slot_key}: {new_state}")

    def _on_tile_right_click(self, slot_key: str):
        logger.info(f"Right click on slot {slot_key} - opening popover")
        mouse_pos = dpg.get_mouse_pos(local=False)
        self.popover.open(slot_key, int(mouse_pos[0]), int(mouse_pos[1]))

    def _start(self):
        active_config = {}
        for slot_key, state in self.slot_states.items():
            if state == "active":
                active_config[slot_key] = self.hotbar[slot_key]

        if active_config:
            self.app_state.killed.clear()
            self.app_state.paused = False
            self.executor.start(active_config)
            logger.info(f"Started with {len(active_config)} active slots")
        else:
            logger.info("No active slots to start")

    def _pause(self):
        self.app_state.toggle_paused()

    def _stop(self):
        self.executor.stop()
        for slot_key in self.slot_states:
            self.slot_states[slot_key] = "off"
            update_tile_state(self.slot_tags[slot_key], "off")
        logger.info("Executor stopped")

    def _poll_status(self):
        mouse_pos = dpg.get_mouse_pos(local=False)
        mx, my = mouse_pos[0], mouse_pos[1]

        vp_pos = dpg.get_viewport_pos()
        vp_x, vp_y = vp_pos[0], vp_pos[1]

        local_mx = mx - vp_x
        local_my = my - vp_y

        clicked_tile = None
        right_clicked_tile = None

        for slot_num in range(1, NUM_SLOTS + 1):
            slot_key = str(slot_num)
            tile_x = 8 + (slot_num - 1) * (TILE_SIZE + TILE_GAP)

            if (tile_x <= local_mx <= tile_x + GLOW_SIZE and
                2 <= local_my <= GLOW_SIZE - 2):

                if dpg.is_mouse_button_clicked(dpg.mvMouseButton_Left):
                    clicked_tile = slot_key
                    logger.debug(f"Left click on slot {slot_key}")
                elif dpg.is_mouse_button_clicked(dpg.mvMouseButton_Right):
                    right_clicked_tile = slot_key
                    logger.debug(f"Right click on slot {slot_key}")

        if clicked_tile:
            self._on_tile_left_click(clicked_tile)
        if right_clicked_tile:
            self._on_tile_right_click(right_clicked_tile)

        over_tile = clicked_tile is not None or right_clicked_tile is not None
        for slot_num in range(1, NUM_SLOTS + 1):
            slot_key = str(slot_num)
            tile_x = 8 + (slot_num - 1) * (TILE_SIZE + TILE_GAP)
            if (tile_x <= local_mx <= tile_x + GLOW_SIZE and
                2 <= local_my <= GLOW_SIZE - 2):
                over_tile = True
                break

        logger.debug(f"Mouse: ({local_mx:.0f}, {local_my:.0f}), Over tile: {over_tile}")

        if self.executor.is_running:
            is_paused = self.app_state.paused
            for slot_num in range(1, NUM_SLOTS + 1):
                slot_key = str(slot_num)
                if self.slot_states[slot_key] == "active" and not is_paused:
                    update_tile_state(self.slot_tags[slot_key], "active")
                else:
                    update_tile_state(self.slot_tags[slot_key], "idle")
        else:
            for slot_key in self.slot_states:
                if self.slot_states[slot_key] == "active":
                    update_tile_state(self.slot_tags[slot_key], "active")
                else:
                    update_tile_state(self.slot_tags[slot_key], "off")

    def _cleanup(self):
        self.executor.stop()
        self.hotkeys.stop()


def main():
    app = BSSAssistApp()
    app.run()
