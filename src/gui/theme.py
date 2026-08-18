import os

import dearpygui.dearpygui as dpg

BG_PRIMARY = (26, 26, 26)
BG_SECONDARY = (42, 42, 42)
TEXT_PRIMARY = (220, 220, 220)
TEXT_MUTED = (140, 140, 140)
TEXT_DIM = (100, 100, 100)
ACCENT = (0, 200, 220)
GREEN = (40, 200, 64)
YELLOW = (254, 188, 46)
RED = (255, 95, 87)
BORDER = (55, 55, 55)

POPUP_BG = (30, 30, 30, 240)
POPUP_BORDER = (60, 60, 60)

FONT_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
    "assets",
    "fonts",
    "JetBrainsMono-Regular.ttf",
)


def register_fonts():
    with dpg.font_registry():
        if os.path.exists(FONT_PATH):
            dpg.add_font(FONT_PATH, 15, tag="mono")
            dpg.add_font(FONT_PATH, 12, tag="mono_small")
            dpg.add_font(FONT_PATH, 18, tag="mono_large")
        else:
            dpg.add_font(dpg.get_font_file(), 15, tag="mono")
            dpg.add_font(dpg.get_font_file(), 12, tag="mono_small")
            dpg.add_font(dpg.get_font_file(), 18, tag="mono_large")
    dpg.bind_font("mono")


def build_theme():
    with dpg.theme(tag="global_theme"):
        with dpg.theme_component(dpg.mvAll):
            dpg.add_theme_style(dpg.mvStyleVar_FrameRounding, 8)
            dpg.add_theme_style(dpg.mvStyleVar_GrabRounding, 6)
            dpg.add_theme_style(dpg.mvStyleVar_WindowPadding, 10, 10)
            dpg.add_theme_style(dpg.mvStyleVar_FramePadding, 8, 5)
            dpg.add_theme_style(dpg.mvStyleVar_ItemSpacing, 8, 6)
            dpg.add_theme_style(dpg.mvStyleVar_ScrollbarRounding, 8)

            dpg.add_theme_color(dpg.mvThemeCol_WindowBg, BG_PRIMARY)
            dpg.add_theme_color(dpg.mvThemeCol_ChildBg, BG_PRIMARY)
            dpg.add_theme_color(dpg.mvThemeCol_FrameBg, BG_SECONDARY)
            dpg.add_theme_color(dpg.mvThemeCol_FrameBgHovered, (50, 50, 50))
            dpg.add_theme_color(dpg.mvThemeCol_FrameBgActive, (55, 55, 55))
            dpg.add_theme_color(dpg.mvThemeCol_Border, BORDER)
            dpg.add_theme_color(dpg.mvThemeCol_Text, TEXT_PRIMARY)
            dpg.add_theme_color(dpg.mvThemeCol_Button, (50, 50, 50))
            dpg.add_theme_color(dpg.mvThemeCol_ButtonHovered, (60, 60, 60))
            dpg.add_theme_color(dpg.mvThemeCol_ButtonActive, (70, 70, 70))
            dpg.add_theme_color(dpg.mvThemeCol_Header, (50, 50, 50))
            dpg.add_theme_color(dpg.mvThemeCol_HeaderHovered, (60, 60, 60))
            dpg.add_theme_color(dpg.mvThemeCol_HeaderActive, (70, 70, 70))
            dpg.add_theme_color(dpg.mvThemeCol_ScrollbarBg, BG_PRIMARY)
            dpg.add_theme_color(dpg.mvThemeCol_ScrollbarGrab, (60, 60, 60))
            dpg.add_theme_color(dpg.mvThemeCol_ScrollbarGrabHovered, (80, 80, 80))
            dpg.add_theme_color(dpg.mvThemeCol_ScrollbarGrabActive, (100, 100, 100))
            dpg.add_theme_color(dpg.mvThemeCol_PopupBg, POPUP_BG)
            dpg.add_theme_color(dpg.mvThemeCol_CheckMark, ACCENT)
            dpg.add_theme_color(dpg.mvThemeCol_SliderGrab, ACCENT)
            dpg.add_theme_color(dpg.mvThemeCol_SliderGrabActive, (0, 220, 240))

    with dpg.theme(tag="transparent_window_theme"):
        with dpg.theme_component(dpg.mvWindowAppItem):
            dpg.add_theme_color(dpg.mvThemeCol_WindowBg, (0, 0, 0, 0))
            dpg.add_theme_color(dpg.mvThemeCol_Border, (0, 0, 0, 0))
            dpg.add_theme_color(dpg.mvThemeCol_ChildBg, (0, 0, 0, 0))

    with dpg.theme(tag="popover_theme"):
        with dpg.theme_component(dpg.mvWindowAppItem):
            dpg.add_theme_color(dpg.mvThemeCol_WindowBg, POPUP_BG)
            dpg.add_theme_color(dpg.mvThemeCol_Border, POPUP_BORDER)
            dpg.add_theme_style(dpg.mvStyleVar_WindowRounding, 10)
            dpg.add_theme_style(dpg.mvStyleVar_WindowPadding, 12, 12)

    with dpg.theme(tag="combo_theme"):
        with dpg.theme_component(dpg.mvCombo):
            dpg.add_theme_color(dpg.mvThemeCol_FrameBg, (35, 35, 35))
            dpg.add_theme_color(dpg.mvThemeCol_FrameBgHovered, (45, 45, 45))
            dpg.add_theme_color(dpg.mvThemeCol_FrameBgActive, (50, 50, 50))

    with dpg.theme(tag="input_theme"):
        with dpg.theme_component(dpg.mvInputInt):
            dpg.add_theme_color(dpg.mvThemeCol_FrameBg, (35, 35, 35))
            dpg.add_theme_color(dpg.mvThemeCol_FrameBgHovered, (45, 45, 45))
            dpg.add_theme_color(dpg.mvThemeCol_FrameBgActive, (50, 50, 50))

    dpg.bind_theme("global_theme")
