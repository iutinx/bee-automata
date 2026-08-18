import logging

import dearpygui.dearpygui as dpg

from src.items import BSS_ITEMS

logger = logging.getLogger(__name__)


class SettingsPopover:
    def __init__(self, app):
        self.app = app
        self._current_slot = None
        self._build_popover()

    def _build_popover(self):
        with dpg.window(
            label="Slot Settings",
            tag="slot_popover",
            no_title_bar=True,
            no_move=False,
            no_resize=True,
            no_collapse=True,
            show=False,
            width=220,
            height=200,
            pos=(0, 0),
        ):
            dpg.add_text("Item", color=(180, 180, 180))
            dpg.add_combo(
                items=BSS_ITEMS,
                width=-1,
                tag="popover_item_combo",
            )

            dpg.add_spacer(height=8)

            dpg.add_text("Interval (ms)", color=(180, 180, 180))
            dpg.add_input_int(
                width=-1,
                tag="popover_interval_input",
                min_value=0,
                min_clamped=True,
                step=0,
            )

            dpg.add_spacer(height=8)

            with dpg.group(horizontal=True):
                dpg.add_checkbox(label="Enabled", tag="popover_enabled_check")
                dpg.add_spacer(width=20)
                dpg.add_button(
                    label="Pick Image",
                    width=90,
                    callback=self._on_pick_image,
                )

            dpg.add_spacer(height=8)

            with dpg.group(horizontal=True):
                dpg.add_button(
                    label="Save",
                    width=70,
                    callback=self._on_save,
                )
                dpg.add_spacer(width=10)
                dpg.add_button(
                    label="Cancel",
                    width=70,
                    callback=self._on_cancel,
                )

    def open(self, slot_key: str, mouse_x: int, mouse_y: int):
        logger.info(f"Opening popover for slot {slot_key} at ({mouse_x}, {mouse_y})")
        self._current_slot = slot_key
        slot_data = self.app.hotbar.get(slot_key, {})

        dpg.configure_item("popover_item_combo", default_value=slot_data.get("item", ""))
        dpg.configure_item("popover_interval_input", default_value=slot_data.get("interval_ms", 0))
        dpg.configure_item("popover_enabled_check", default_value=slot_data.get("enabled", False))

        dpg.configure_item("slot_popover", pos=(mouse_x + 10, mouse_y))
        dpg.show_item("slot_popover")
        logger.info("Popover shown")

    def close(self):
        dpg.hide_item("slot_popover")
        self._current_slot = None

    def _on_pick_image(self):
        if not self._current_slot:
            return
        dpg.show_item("popover_image_dialog")

    def _on_save(self):
        if not self._current_slot:
            return
        slot_key = self._current_slot
        item = dpg.get_value("popover_item_combo")
        interval = dpg.get_value("popover_interval_input")
        enabled = dpg.get_value("popover_enabled_check")

        self.app.hotbar[slot_key] = {
            "item": item,
            "interval_ms": interval,
            "enabled": enabled,
        }
        logger.info(f"Slot {slot_key} updated: {item}, {interval}ms, enabled={enabled}")
        self.close()

    def _on_cancel(self):
        self.close()

    def on_image_selected(self, sender, app_data):
        if not self._current_slot:
            return
        path = app_data["file_path_name"]
        self.app.slot_icons.set_icon_path(self._current_slot, path)
        logger.info(f"Slot {self._current_slot} image set: {path}")
