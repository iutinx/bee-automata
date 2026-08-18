import dearpygui.dearpygui as dpg

TILE_SIZE = 64
GLOW_SIZE = 68
GLOW_OFFSET = -2

GLOW_COLORS = {
    "active": (40, 200, 64, 180),
    "idle": (100, 100, 100, 180),
    "off": (0, 0, 0, 0),
}

TILE_BORDER = (140, 125, 100)
TILE_GRADIENT_TOP = (210, 195, 170)
TILE_GRADIENT_MID1 = (200, 185, 160)
TILE_GRADIENT_MID2 = (190, 175, 150)
TILE_GRADIENT_BOT = (185, 170, 145)
TILE_HIGHLIGHT = (225, 215, 195)

BADGE_BG = (40, 35, 30, 230)
BADGE_TEXT = (255, 255, 255)

COUNT_SHADOW = (0, 0, 0, 200)
COUNT_TEXT = (255, 255, 255)


class SlotIcons:
    def __init__(self):
        self._icons: dict = {}
        self._quantities: dict = {}

    def get_icon_path(self, slot_key: str):
        return self._icons.get(slot_key)

    def set_icon_path(self, slot_key: str, path: str):
        self._icons[slot_key] = path

    def clear_icon(self, slot_key: str):
        self._icons.pop(slot_key, None)

    def set_quantity(self, slot_key: str, qty: int):
        self._quantities[slot_key] = qty

    def get_quantity(self, slot_key: str) -> int:
        return self._quantities.get(slot_key, 0)


def draw_slot_tile(
    parent: str,
    slot_key: str,
    drawlist_tag: str,
    state: str = "off",
    quantity: int = 0,
):
    import logging
    logger = logging.getLogger(__name__)
    logger.debug(f"draw_slot_tile: parent={parent}, tag={drawlist_tag}")
    
    s = TILE_SIZE
    g = GLOW_SIZE
    off = GLOW_OFFSET

    dl = dpg.add_drawlist(width=g, height=g, parent=parent, tag=drawlist_tag)

    glow_color = GLOW_COLORS.get(state, GLOW_COLORS["off"])
    dpg.draw_rectangle(
        (0, 0), (g, g),
        color=glow_color, fill=glow_color,
        rounding=10, thickness=0, parent=dl, tag=f"{drawlist_tag}_glow",
    )

    tx, ty = -off, -off

    dpg.draw_rectangle(
        (tx, ty), (tx + s, ty + s),
        color=TILE_BORDER, fill=TILE_BORDER,
        rounding=8, thickness=2, parent=dl, tag=f"{drawlist_tag}_border",
    )

    strip_h = s // 4
    for i, color in enumerate([TILE_GRADIENT_TOP, TILE_GRADIENT_MID1, TILE_GRADIENT_MID2, TILE_GRADIENT_BOT]):
        y1 = ty + i * strip_h + 2
        y2 = ty + (i + 1) * strip_h + 2
        dpg.draw_rectangle(
            (tx + 2, y1), (tx + s - 2, y2),
            color=color, fill=color,
            rounding=6 if i == 0 else 0,
            thickness=0, parent=dl, tag=f"{drawlist_tag}_grad_{i}",
        )

    dpg.draw_rectangle(
        (tx + 3, ty + 3), (tx + s - 3, ty + 12),
        color=TILE_HIGHLIGHT, fill=TILE_HIGHLIGHT,
        rounding=5, thickness=0, parent=dl, tag=f"{drawlist_tag}_highlight",
    )

    badge_w = 22
    badge_h = 18
    dpg.draw_rectangle(
        (tx + 3, ty + 3), (tx + 3 + badge_w, ty + 3 + badge_h),
        color=BADGE_BG, fill=BADGE_BG,
        rounding=5, thickness=0, parent=dl, tag=f"{drawlist_tag}_badge_bg",
    )

    badge_text = f"[{slot_key}]"
    dpg.draw_text(
        (tx + 5, ty + 4), badge_text,
        size=10, color=BADGE_TEXT, parent=dl, tag=f"{drawlist_tag}_badge_text",
    )

    icon_size = 48
    icon_x = tx + (s - icon_size) // 2
    icon_y = ty + (s - icon_size) // 2 - 4
    dpg.draw_rectangle(
        (icon_x, icon_y), (icon_x + icon_size, icon_y + icon_size),
        color=(180, 180, 180, 100), fill=(180, 180, 180, 50),
        rounding=6, thickness=1, parent=dl, tag=f"{drawlist_tag}_icon_bg",
    )
    dpg.draw_text(
        (tx + s // 2 - 5, ty + s // 2 - 10), "+",
        size=18, color=(160, 160, 160), parent=dl, tag=f"{drawlist_tag}_icon_placeholder",
    )

    count_text = f"x{quantity}" if quantity > 0 else ""
    if count_text:
        dpg.draw_text(
            (tx + s // 2 - 20, ty + s - 16), count_text,
            size=12, color=COUNT_SHADOW, parent=dl, tag=f"{drawlist_tag}_count_shadow",
        )
        dpg.draw_text(
            (tx + s // 2 - 21, ty + s - 17), count_text,
            size=12, color=COUNT_TEXT, parent=dl, tag=f"{drawlist_tag}_count_text",
        )
    else:
        dpg.draw_text(
            (tx + s // 2 - 20, ty + s - 16), "",
            size=12, color=COUNT_SHADOW, parent=dl, tag=f"{drawlist_tag}_count_shadow",
        )
        dpg.draw_text(
            (tx + s // 2 - 21, ty + s - 17), "",
            size=12, color=COUNT_TEXT, parent=dl, tag=f"{drawlist_tag}_count_text",
        )

    return {
        "glow": f"{drawlist_tag}_glow",
        "border": f"{drawlist_tag}_border",
        "badge_bg": f"{drawlist_tag}_badge_bg",
        "badge_text": f"{drawlist_tag}_badge_text",
        "icon_bg": f"{drawlist_tag}_icon_bg",
        "icon_placeholder": f"{drawlist_tag}_icon_placeholder",
        "count_shadow": f"{drawlist_tag}_count_shadow",
        "count_text": f"{drawlist_tag}_count_text",
    }


def update_tile_state(tags: dict, state: str):
    glow_color = GLOW_COLORS.get(state, GLOW_COLORS["off"])
    dpg.configure_item(tags["glow"], color=glow_color, fill=glow_color)


def update_tile_count(tags: dict, quantity: int):
    count_text = f"x{quantity}" if quantity > 0 else ""
    dpg.configure_item(tags["count_shadow"], default_value=count_text)
    dpg.configure_item(tags["count_text"], default_value=count_text)


def draw_status_dot(parent: str, tag: str, state: str):
    color_map = {
        "running": (40, 200, 64),
        "paused": (254, 188, 46),
        "stopped": (100, 100, 100),
        "idle": (100, 100, 100),
    }
    color = color_map.get(state, (100, 100, 100))
    dl = dpg.add_drawing(width=10, height=10, parent=parent, tag=f"{tag}_dl")
    dpg.draw_circle((5, 5), 4, color=color, fill=color, parent=dl, tag=tag)


def update_status_dot(tag: str, state: str):
    color_map = {
        "running": (40, 200, 64),
        "paused": (254, 188, 46),
        "stopped": (100, 100, 100),
        "idle": (100, 100, 100),
    }
    color = color_map.get(state, (100, 100, 100))
    dpg.configure_item(tag, color=color, fill=color)
