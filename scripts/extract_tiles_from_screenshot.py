#!/usr/bin/env python3
"""
Interactive tool to pick tile coordinates from a Mahjong Soul screenshot.

Usage:
    python scripts/extract_tiles_from_screenshot.py <screenshot.png>

This opens a window where you click on each tile's top-left corner.
The script saves coordinates to coords.json that can be used with
generate_tile_templates.py.

Requires: pip install Pillow
"""
import sys
import json
from PIL import Image, ImageTk
import tkinter as tk
from tkinter import messagebox

ALL_TILES = []
for suit in ["m", "p", "s"]:
    for rank in range(1, 10):
        ALL_TILES.append(f"{rank}{suit}")
HONOR_TILES = ["東", "南", "西", "北", "白", "發", "中"]
ALL_TILES.extend(HONOR_TILES)


class TilePicker:
    def __init__(self, img_path):
        self.img = Image.open(img_path)
        self.coords = {}
        self.current_tile_idx = 0
        self.scale = 1.0

        # Resize for display if too large
        max_dim = 1200
        if self.img.width > max_dim or self.img.height > max_dim:
            self.scale = max_dim / max(self.img.width, self.img.height)
            display_size = (int(self.img.width * self.scale), int(self.img.height * self.scale))
            self.display_img = self.img.resize(display_size, Image.LANCZOS)
        else:
            self.display_img = self.img

        self.root = tk.Tk()
        self.root.title(f"Click on tile: {ALL_TILES[0]}")

        self.tk_img = ImageTk.PhotoImage(self.display_img)
        self.canvas = tk.Canvas(
            self.root,
            width=self.display_img.width,
            height=self.display_img.height
        )
        self.canvas.create_image(0, 0, anchor=tk.NW, image=self.tk_img)
        self.canvas.pack()

        self.canvas.bind("<Button-1>", self.on_click)
        self.root.bind("<Escape>", lambda e: self.save_and_exit())

    def on_click(self, event):
        if self.current_tile_idx >= len(ALL_TILES):
            return

        # Convert display coordinates back to original image coordinates
        x = int(event.x / self.scale)
        y = int(event.y / self.scale)
        tile_name = ALL_TILES[self.current_tile_idx]
        self.coords[tile_name] = [x, y]
        print(f"  {tile_name}: ({x}, {y})")

        self.current_tile_idx += 1
        if self.current_tile_idx < len(ALL_TILES):
            self.root.title(f"Click on tile: {ALL_TILES[self.current_tile_idx]} ({self.current_tile_idx + 1}/{len(ALL_TILES)})")
        else:
            self.save_and_exit()

    def save_and_exit(self):
        output = "coords.json"
        with open(output, "w", encoding="utf-8") as f:
            json.dump(self.coords, f, ensure_ascii=False, indent=2)
        print(f"\nSaved {len(self.coords)} coordinates to {output}")
        self.root.destroy()

    def run(self):
        print(f"Click on each of the 34 tiles (1m, 2m, ..., 中).")
        print(f"Press Escape to save and exit early.")
        self.root.mainloop()


def main():
    if len(sys.argv) != 2:
        print("Usage: python extract_tiles_from_screenshot.py <screenshot.png>")
        sys.exit(1)

    picker = TilePicker(sys.argv[1])
    picker.run()


if __name__ == "__main__":
    main()
