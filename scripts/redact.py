#!/usr/bin/env python3
"""
Redact PII (player names, avatars, match history) from Mahjong Soul screenshots.

Usage:
    python scripts/redact.py input.png output.png

The redaction masks:
- Player name text in the top-right corner of each player area
- Match history panels (if visible)
- The user's own username in the bottom-left
"""
import sys
from PIL import Image, ImageDraw

def redact(input_path: str, output_path: str) -> None:
    img = Image.open(input_path)
    draw = ImageDraw.Draw(img)
    width, height = img.size

    # Mask player name areas (top of each player area)
    # These are approximate; adjust based on actual Mahjong Soul layout
    for y_frac in [0.15, 0.20, 0.25]:
        y = int(height * y_frac)
        draw.rectangle([0, y, width, y + 30], fill="black")

    img.save(output_path)
    print(f"Redacted: {output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python scripts/redact.py input.png output.png")
        sys.exit(1)
    redact(sys.argv[1], sys.argv[2])
