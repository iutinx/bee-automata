import logging

from src.gui.app import main as gui_main

logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)


def main():
    gui_main()


if __name__ == "__main__":
    main()
