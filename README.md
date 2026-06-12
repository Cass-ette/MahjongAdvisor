# MahjongAdvisor

macOS native advisor for Mahjong Soul (雀魂). OCRs the game window and shows
the recommended discard in a small floating panel.

## Status

**v0.1 — Internal alpha.** The MahjongCore algorithm is feature-complete with
30+ unit tests. The MahjongOCR pipeline is structurally complete; real-world
accuracy requires calibration against Mahjong Soul screenshots. The App shell
is functional but the edit-mode UX is stubbed.

## Build

```bash
swift build
```

## Run

```bash
swift run MahjongAdvisorApp
```

Requires macOS 14.0+ and Screen Recording permission (granted on first launch).

## Test

```bash
swift test
```

OCR integration tests are skipped on CI (no `CGWindowListCopyWindowInfo` /
`ScreenCaptureKit` in headless runners). Run locally with:

```bash
swift test --filter OCR
```

## Calibration

The first time you use MahjongAdvisor, the OCR crop coordinates may not match
your Mahjong Soul window. Use **Menu Bar → 校准窗口布局** to walk through
clicking 5 anchor points.

See `docs/superpowers/specs/2026-06-06-mahjong-advisor-design.md` for the
full design spec and `docs/superpowers/plans/2026-06-06-mahjong-advisor.md`
for the implementation plan.
