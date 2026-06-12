#!/usr/bin/env python3
"""
Evaluate hybrid OCR accuracy on labeled Mahjong Soul screenshots.

Usage:
    python scripts/evaluate.py \\
        --screenshots data/test_screenshots/ \\
        --ground-truth data/test_ground_truth/ \\
        --report data/metrics.json

For each screenshot with ground truth:
1. Run template matching (and Vision OCR)
2. Compare to ground truth
3. Compute per-tile accuracy, per-screenshot accuracy, overall accuracy

Ground truth format (JSON):
    {
        "tiles": [
            {"name": "1m", "x": 260, "y": 980, "w": 32, "h": 44},
            {"name": "2m", "x": 295, "y": 980, "w": 32, "h": 44},
            ...
        ]
    }

Output metrics.json:
    {
        "total_tiles": 100,
        "correct_tiles": 87,
        "per_tile_accuracy": 0.87,
        "per_screenshot_accuracy": [...],
        "confusion_matrix": {"1m": {"actual": {"1m": 10, "2m": 0, ...}}, ...},
        "error_cases": [...]
    }

For v1, this is a STRUCTURAL evaluation tool that:
- Loads ground truth
- Runs template matching on each tile region
- Compares predictions to ground truth
- Reports metrics

It does NOT actually call the Swift HybridOCREngine (cross-language).
For real evaluation, the Swift engine would need to be invoked separately.
"""
import argparse
import json
import sys
from pathlib import Path
from collections import defaultdict
from PIL import Image
import numpy as np


def load_ground_truth(gt_path):
    """Load ground truth JSON file."""
    with open(gt_path, "r", encoding="utf-8") as f:
        return json.load(f)


def perceptual_hash(img, hash_size=8):
    """Compute perceptual hash for matching."""
    img = img.convert("L").resize((hash_size, hash_size), Image.LANCZOS)
    arr = np.array(img, dtype=np.float32)
    avg = arr.mean()
    return tuple((arr > avg).flatten())


def hamming_distance(hash1, hash2):
    """Compute Hamming distance between hashes."""
    return sum(a != b for a, b in zip(hash1, hash2))


def load_templates(templates_dir):
    """Load all 34 tile templates and compute their hashes."""
    templates = {}
    for template_path in sorted(templates_dir.glob("*.png")):
        # Strip suffix like "_orig", "_bright_0.8" etc.
        name = template_path.stem
        if "_" in name:
            tile_name = name.split("_")[0]
        else:
            tile_name = name

        img = Image.open(template_path)
        h = perceptual_hash(img)
        if tile_name not in templates:
            templates[tile_name] = []
        templates[tile_name].append((h, img))
    return templates


def match_tile(tile_img, templates, top_k=3):
    """Match a tile image against all templates, return top-K (name, distance)."""
    target_hash = perceptual_hash(tile_img)
    matches = []
    for tile_name, variants in templates.items():
        for h, img in variants:
            dist = hamming_distance(target_hash, h)
            matches.append((tile_name, dist))
    matches.sort(key=lambda x: x[1])
    return matches[:top_k]


def evaluate_screenshot(screenshot_path, ground_truth, templates):
    """Evaluate one screenshot, return per-tile results."""
    img = Image.open(screenshot_path)
    results = []

    for tile_gt in ground_truth["tiles"]:
        name = tile_gt["name"]
        x, y = tile_gt["x"], tile_gt["y"]
        w = tile_gt.get("w", 32)
        h = tile_gt.get("h", 44)

        # Extract tile region
        tile_img = img.crop((x, y, x + w, y + h))

        # Match against templates
        top_matches = match_tile(tile_img, templates, top_k=1)
        predicted = top_matches[0][0] if top_matches else "?"

        results.append({
            "ground_truth": name,
            "predicted": predicted,
            "correct": predicted == name,
            "confidence": top_matches[0][1] if top_matches else 0,  # Hamming distance
            "x": x, "y": y
        })

    return results


def compute_metrics(all_results):
    """Compute aggregate metrics from per-screenshot results."""
    total = sum(len(r) for r in all_results)
    correct = sum(1 for r in all_results for tile in r if tile["correct"])

    per_screenshot_accuracy = []
    for r in all_results:
        if r:
            correct_in_screenshot = sum(1 for tile in r if tile["correct"])
            per_screenshot_accuracy.append(correct_in_screenshot / len(r))

    # Confusion matrix
    confusion = defaultdict(lambda: defaultdict(int))
    for r in all_results:
        for tile in r:
            confusion[tile["ground_truth"]][tile["predicted"]] += 1

    # Error cases (for debugging)
    error_cases = []
    for r in all_results:
        for tile in r:
            if not tile["correct"]:
                error_cases.append(tile)

    return {
        "total_tiles": total,
        "correct_tiles": correct,
        "per_tile_accuracy": correct / total if total > 0 else 0.0,
        "per_screenshot_accuracy": per_screenshot_accuracy,
        "mean_per_screenshot_accuracy": np.mean(per_screenshot_accuracy) if per_screenshot_accuracy else 0.0,
        "confusion_matrix": {k: dict(v) for k, v in confusion.items()},
        "error_count": len(error_cases),
        "sample_errors": error_cases[:10]  # First 10 errors
    }


def main():
    parser = argparse.ArgumentParser(description="Evaluate hybrid OCR accuracy")
    parser.add_argument("--screenshots", required=True, help="Directory with test screenshots")
    parser.add_argument("--ground-truth", required=True, help="Directory with ground truth JSONs")
    parser.add_argument("--templates", default="data/templates/", help="Directory with tile templates")
    parser.add_argument("--report", required=True, help="Output metrics JSON file")
    args = parser.parse_args()

    screenshots_dir = Path(args.screenshots)
    gt_dir = Path(args.ground_truth)
    templates_dir = Path(args.templates)
    report_path = Path(args.report)
    report_path.parent.mkdir(parents=True, exist_ok=True)

    if not templates_dir.exists():
        print(f"ERROR: Templates directory not found: {templates_dir}")
        print("Run batch_extract.py first to generate templates.")
        sys.exit(1)

    # Load templates
    print(f"Loading templates from {templates_dir}/")
    templates = load_templates(templates_dir)
    print(f"Loaded {len(templates)} unique tile types\n")

    # Find matching pairs
    screenshot_files = sorted(screenshots_dir.glob("*.png"))
    if not screenshot_files:
        print(f"No screenshots found in {screenshots_dir}")
        sys.exit(1)

    print(f"Found {len(screenshot_files)} test screenshots")
    print(f"Evaluating...\n")

    # Evaluate each screenshot
    all_results = []
    for screenshot_path in screenshot_files:
        gt_path = gt_dir / f"{screenshot_path.stem}.json"
        if not gt_path.exists():
            print(f"⚠ Skipping {screenshot_path.name}: no ground truth")
            continue

        ground_truth = load_ground_truth(gt_path)
        results = evaluate_screenshot(screenshot_path, ground_truth, templates)
        all_results.append(results)

        # Per-screenshot summary
        correct = sum(1 for r in results if r["correct"])
        total = len(results)
        accuracy = correct / total if total > 0 else 0
        print(f"  {screenshot_path.name}: {correct}/{total} = {accuracy:.1%}")

    if not all_results:
        print("\nNo results. Check that ground truth files match screenshot names.")
        sys.exit(1)

    # Compute metrics
    metrics = compute_metrics(all_results)

    # Save report
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(metrics, f, ensure_ascii=False, indent=2)

    # Print summary
    print(f"\n=== Overall Metrics ===")
    print(f"Total tiles:       {metrics['total_tiles']}")
    print(f"Correct tiles:     {metrics['correct_tiles']}")
    print(f"Per-tile accuracy: {metrics['per_tile_accuracy']:.1%}")
    print(f"Mean per-screenshot: {metrics['mean_per_screenshot_accuracy']:.1%}")
    print(f"Error count:       {metrics['error_count']}")

    if metrics["sample_errors"]:
        print(f"\n=== Sample Errors (first 10) ===")
        for err in metrics["sample_errors"]:
            print(f"  GT={err['ground_truth']:>4}  Predicted={err['predicted']:>4}  at ({err['x']}, {err['y']})")

    print(f"\nFull report saved to: {report_path}")


if __name__ == "__main__":
    main()
