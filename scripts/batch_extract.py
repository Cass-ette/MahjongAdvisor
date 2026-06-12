#!/usr/bin/env python3
"""
Batch extract 34 tile templates from multiple screenshots.

Usage:
    python scripts/batch_extract.py \\
        --screenshots data/screenshots/ \\
        --coords data/coords/ \\
        --output data/templates/ \\
        [--size 32x44]

Workflow:
1. Scan screenshots/ and coords/ for matching pairs (screenshot.png + screenshot.json)
2. For each pair, extract the 34 tile regions
3. Deduplicate by perceptual hash (keep the sharpest)
4. Output: data/templates/<tile_name>.png (one per tile, best quality)

Directory structure expected:
    data/
    ├── screenshots/
    │   ├── game_01.png
    │   ├── game_02.png
    │   └── ...
    └── coords/
        ├── game_01.json  ({"1m": [x, y], "2m": [x, y], ...})
        ├── game_02.json
        └── ...

Coords JSON format:
    {
        "1m": [260, 980],
        "2m": [295, 980],
        "東": [800, 100],
        ...
    }

Output:
    data/templates/1m.png, 2m.png, ..., 中.png (34 files)

Requires: pip install Pillow numpy
"""
import argparse
import json
import sys
from pathlib import Path
from collections import defaultdict
from PIL import Image, ImageFilter
import numpy as np


# 34 tiles: 1-9m, 1-9p, 1-9s, 東南西北白發中
ALL_TILES = []
for suit in ["m", "p", "s"]:
    for rank in range(1, 10):
        ALL_TILES.append(f"{rank}{suit}")
ALL_TILES.extend(["東", "南", "西", "北", "白", "發", "中"])


def extract_tile(img, x, y, w, h):
    """Extract a single tile region."""
    return img.crop((x, y, x + w, y + h))


def compute_sharpness(img):
    """Compute Laplacian variance as sharpness score (higher = sharper)."""
    gray = np.array(img.convert("L"), dtype=np.float32)
    laplacian = np.array(
        Image.fromarray(gray).filter(ImageFilter.FIND_EDGES)
    )
    return float(np.var(laplacian))


def compute_hash(img, hash_size=8):
    """Compute perceptual hash (average hash) for deduplication."""
    img = img.convert("L").resize((hash_size, hash_size), Image.LANCZOS)
    arr = np.array(img, dtype=np.float32)
    avg = arr.mean()
    return tuple((arr > avg).flatten())


def hamming_distance(hash1, hash2):
    """Compute Hamming distance between two hashes."""
    return sum(a != b for a, b in zip(hash1, hash2))


def parse_size(size_str):
    """Parse 'WxH' string to (w, h) tuple."""
    try:
        w, h = size_str.split("x")
        return int(w), int(h)
    except ValueError:
        raise argparse.ArgumentTypeError(f"Invalid size format: {size_str} (expected WxH, e.g., 32x44)")


def load_coords(coords_path):
    """Load coordinates from JSON file."""
    with open(coords_path, "r", encoding="utf-8") as f:
        return json.load(f)


def process_screenshot(screenshot_path, coords_path, tile_size):
    """Process one screenshot and return {tile_name: (image, sharpness)}."""
    img = Image.open(screenshot_path)
    coords = load_coords(coords_path)
    w, h = tile_size
    results = {}

    for tile_name, (x, y) in coords.items():
        if tile_name not in ALL_TILES:
            print(f"  ⚠ Skipping unknown tile: {tile_name}")
            continue
        try:
            tile_img = extract_tile(img, x, y, w, h)
            sharpness = compute_sharpness(tile_img)
            results[tile_name] = (tile_img, sharpness)
        except Exception as e:
            print(f"  ✗ Failed to extract {tile_name}: {e}")

    return results


def deduplicate_and_pick_best(all_results):
    """For each tile, pick the sharpest image among duplicates (by hash)."""
    best = {}  # tile_name -> (image, sharpness, hash)

    for tile_name, (img, sharpness) in all_results.items():
        h = compute_hash(img)
        if tile_name not in best:
            best[tile_name] = (img, sharpness, h)
        else:
            current_sharpness = best[tile_name][1]
            if sharpness > current_sharpness:
                best[tile_name] = (img, sharpness, h)

    return best


def main():
    parser = argparse.ArgumentParser(description="Batch extract tile templates")
    parser.add_argument("--screenshots", required=True, help="Directory with screenshot PNGs")
    parser.add_argument("--coords", required=True, help="Directory with coords JSON files")
    parser.add_argument("--output", required=True, help="Output directory for templates")
    parser.add_argument("--size", type=parse_size, default="32x44",
                       help="Tile size in WxH (default: 32x44)")
    args = parser.parse_args()

    screenshots_dir = Path(args.screenshots)
    coords_dir = Path(args.coords)
    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)

    # Find matching pairs
    screenshot_files = sorted(screenshots_dir.glob("*.png"))
    if not screenshot_files:
        print(f"No PNG files found in {screenshots_dir}")
        sys.exit(1)

    print(f"Found {len(screenshot_files)} screenshots")
    print(f"Tile size: {args.size[0]}x{args.size[1]}")
    print(f"Output: {output_dir}\n")

    # Process all screenshots
    all_results = []
    for screenshot_path in screenshot_files:
        coords_path = coords_dir / f"{screenshot_path.stem}.json"
        if not coords_path.exists():
            print(f"⚠ Skipping {screenshot_path.name}: no coords file")
            continue

        print(f"Processing: {screenshot_path.name}")
        results = process_screenshot(screenshot_path, coords_path, args.size)
        all_results.append(results)
        print(f"  Extracted {len(results)} tiles")

    if not all_results:
        print("\nNo tiles extracted. Check that coords files match screenshot names.")
        sys.exit(1)

    # Merge all results
    merged = {}
    for results in all_results:
        merged.update(results)

    # Deduplicate and pick best
    best = deduplicate_and_pick_best(merged)

    # Check coverage
    missing = set(ALL_TILES) - set(best.keys())
    if missing:
        print(f"\n⚠ Missing {len(missing)} tiles: {sorted(missing)}")
        print("  You need more screenshots to cover all 34 tiles.")

    # Save
    print(f"\nSaving {len(best)} unique templates to {output_dir}/")
    for tile_name, (img, sharpness, h) in best.items():
        out_file = output_dir / f"{tile_name}.png"
        img.save(out_file)

    # Summary
    print(f"\n=== Summary ===")
    print(f"Templates generated: {len(best)}/34")
    if missing:
        print(f"Missing: {', '.join(sorted(missing))}")
    print(f"\nNext steps:")
    print(f"1. Check templates visually in {output_dir}/")
    print(f"2. Copy to Swift bundle: cp {output_dir}/*.png MahjongOCR/Sources/MahjongOCR/Resources/TileTemplates/")
    print(f"3. Rebuild: swift build --package-path MahjongOCR")


if __name__ == "__main__":
    main()
