#!/usr/bin/env python3
"""
Generate 34 tile template images from a Mahjong Soul screenshot.

Usage:
    python scripts/generate_tile_templates.py <screenshot.png> <output_dir>

The script:
1. Loads a Mahjong Soul screenshot
2. For each known tile (1-9m/p/s + 7 honors), crops the tile region
3. Saves each crop as <output_dir>/<tile_name>.png

For v1, the tile coordinates are hardcoded based on a reference screenshot.
In future, coordinates can be auto-detected via template matching.

Requires: pip install Pillow
"""
import sys
import os
from pathlib import Path
from PIL import Image

# 34 tiles: 1-9 of each suit (m/p/s) + 7 honors
ALL_TILES = []

# Number tiles: 1m, 2m, ..., 9m, 1p, ..., 9p, 1s, ..., 9s
SUIT_NAMES = {"m": "萬", "p": "筒", "s": "索"}
for suit in ["m", "p", "s"]:
    for rank in range(1, 10):
        ALL_TILES.append(f"{rank}{suit}")

# Honor tiles: 東南西北白發中
HONOR_TILES = ["東", "南", "西", "北", "白", "發", "中"]
ALL_TILES.extend(HONOR_TILES)

# v1: Approximate coordinates (based on 1920x1080 Mahjong Soul client)
# Each tile is ~32x44 pixels
# User should provide --coords-json to override
DEFAULT_COORDS = {
    # Bottom row (your hand) - 14 tiles spaced ~35px apart starting at (260, 980)
    # Adjust based on your screenshot
}


def extract_tile(img, x, y, w=32, h=44):
    """Extract a single tile region from the image."""
    return img.crop((x, y, x + w, y + h))


def generate_templates(screenshot_path: str, output_dir: str, coords: dict) -> None:
    """Generate all 34 tile templates from a screenshot."""
    img = Image.open(screenshot_path)
    out_path = Path(output_dir)
    out_path.mkdir(parents=True, exist_ok=True)

    print(f"Loaded screenshot: {screenshot_path} ({img.size[0]}x{img.size[1]})")
    print(f"Output directory: {output_dir}")
    print(f"Generating {len(coords)} templates...")

    for tile_name, (x, y) in coords.items():
        try:
            tile_img = extract_tile(img, x, y)
            out_file = out_path / f"{tile_name}.png"
            tile_img.save(out_file)
            print(f"  ✓ {tile_name}.png ({tile_img.size[0]}x{tile_img.size[1]})")
        except Exception as e:
            print(f"  ✗ {tile_name}.png failed: {e}")

    print(f"\nDone! Generated {len(coords)} templates in {output_dir}")
    print("Next: bundle these PNGs into MahjongOCR/Resources/TileTemplates/")


def main():
    if len(sys.argv) < 3:
        print("Usage: python generate_tile_templates.py <screenshot.png> <output_dir> [coords.json]")
        print()
        print("Coords JSON format:")
        print('  {')
        print('    "1m": [260, 980],')
        print('    "2m": [295, 980],')
        print('    ...')
        print('    "中": [800, 980]')
        print('  }')
        print()
        print("Or use --interactive to click on tiles in the screenshot.")
        sys.exit(1)

    screenshot = sys.argv[1]
    output_dir = sys.argv[2]
    coords_file = sys.argv[3] if len(sys.argv) > 3 else None

    if coords_file and os.path.exists(coords_file):
        import json
        with open(coords_file) as f:
            coords = json.load(f)
        print(f"Loaded {len(coords)} coordinates from {coords_file}")
    else:
        print("ERROR: No coordinates file provided.")
        print()
        print("You need to create a coords.json file with tile positions.")
        print("See the example format in the usage message above.")
        print()
        print("Tip: Open the screenshot in an image editor and note the (x, y)")
        print("     of each tile's top-left corner.")
        sys.exit(1)

    generate_templates(screenshot, output_dir, coords)


if __name__ == "__main__":
    main()
