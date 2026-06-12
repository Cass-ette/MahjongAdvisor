#!/usr/bin/env python3
"""
Augment tile templates with brightness/contrast/rotation/noise variants.

Usage:
    python scripts/augment_templates.py \\
        --input data/templates/ \\
        --output data/templates_augmented/ \\
        [--variants 5]

Each input template generates N variants:
- 1.0x brightness
- 0.8x / 1.2x brightness
- ±2° rotation
- Gaussian noise (σ=2, 5)
- Slight scale (0.95x, 1.05x)

Output: data/templates_augmented/<tile_name>_<variant>.png

Requires: pip install Pillow numpy
"""
import argparse
import sys
from pathlib import Path
from PIL import Image, ImageEnhance, ImageFilter
import numpy as np
import random


def add_noise(img, sigma=2.0):
    """Add Gaussian noise to image."""
    arr = np.array(img, dtype=np.float32)
    noise = np.random.normal(0, sigma, arr.shape)
    arr = np.clip(arr + noise, 0, 255).astype(np.uint8)
    return Image.fromarray(arr)


def rotate(img, angle, fillcolor=(255, 255, 255)):
    """Rotate image by angle (degrees), with white fill."""
    return img.rotate(angle, resample=Image.BILINEAR, fillcolor=fillcolor)


def scale(img, factor, target_size=None):
    """Scale image by factor, optionally resize back to target_size."""
    w, h = img.size
    new_size = (int(w * factor), int(h * factor))
    scaled = img.resize(new_size, Image.LANCZOS)
    if target_size:
        scaled = scaled.resize(target_size, Image.LANCZOS)
    return scaled


def adjust_brightness(img, factor):
    """Adjust brightness (factor < 1 = darker, > 1 = brighter)."""
    enhancer = ImageEnhance.Brightness(img)
    return enhancer.enhance(factor)


def adjust_contrast(img, factor):
    """Adjust contrast."""
    enhancer = ImageEnhance.Contrast(img)
    return enhancer.enhance(factor)


def generate_variants(img, n_variants=5, seed=None):
    """Generate N augmented variants of the tile image."""
    if seed is not None:
        random.seed(seed)

    variants = [("orig", img)]  # Always keep original
    base_size = img.size

    # Brightness variants
    variants.append(("bright_0.8", adjust_brightness(img, 0.8)))
    variants.append(("bright_1.2", adjust_brightness(img, 1.2)))

    # Contrast variants
    variants.append(("contrast_0.8", adjust_contrast(img, 0.8)))
    variants.append(("contrast_1.2", adjust_contrast(img, 1.2)))

    # Rotation variants
    for angle in [-2, 2]:
        variants.append((f"rot_{angle}", rotate(img, angle)))

    # Scale variants
    for factor in [0.95, 1.05]:
        variants.append((f"scale_{factor}", scale(img, factor, target_size=base_size)))

    # Noise variants
    for sigma in [2.0, 5.0]:
        variants.append((f"noise_{sigma}", add_noise(img, sigma)))

    # Slight blur (compression artifacts)
    variants.append(("blur", img.filter(ImageFilter.GaussianBlur(radius=0.5))))

    # Sample N variants randomly (always include original)
    if n_variants < len(variants):
        other_variants = variants[1:]  # Skip original
        sampled = random.sample(other_variants, n_variants - 1)
        variants = [variants[0]] + sampled

    return variants


def main():
    parser = argparse.ArgumentParser(description="Augment tile templates")
    parser.add_argument("--input", required=True, help="Input directory with 34 template PNGs")
    parser.add_argument("--output", required=True, help="Output directory for augmented templates")
    parser.add_argument("--variants", type=int, default=5,
                       help="Number of variants per tile (including original, default: 5)")
    parser.add_argument("--seed", type=int, default=42, help="Random seed (default: 42)")
    args = parser.parse_args()

    input_dir = Path(args.input)
    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)

    input_files = sorted(input_dir.glob("*.png"))
    if not input_files:
        print(f"No PNG files found in {input_dir}")
        sys.exit(1)

    print(f"Found {len(input_files)} input templates")
    print(f"Generating {args.variants} variants per template")
    print(f"Output: {output_dir}\n")

    total_variants = 0
    for input_path in input_files:
        tile_name = input_path.stem
        img = Image.open(input_path)
        variants = generate_variants(img, n_variants=args.variants, seed=args.seed)

        print(f"{tile_name}: {len(variants)} variants")
        for variant_name, variant_img in variants:
            out_file = output_dir / f"{tile_name}_{variant_name}.png"
            variant_img.save(out_file)
            total_variants += 1

    print(f"\n=== Summary ===")
    print(f"Total augmented templates: {total_variants}")
    print(f"Originals + variants per tile: {args.variants}")
    print(f"\nNext steps:")
    print(f"1. Inspect augmented templates in {output_dir}/")
    print(f"2. Optionally combine with originals: cp {input_dir}/*.png {output_dir}/")
    print(f"3. Bundle into Swift resources")


if __name__ == "__main__":
    main()
