# MahjongAdvisor

A macOS native SwiftUI app that assists with Japanese riichi mahjong (Mahjong Soul / 雀魂) by providing real-time discard recommendations.

## Features

- Observes Mahjong Soul game window via screen capture
- OCRs hand and table state every 3 seconds
- Computes best discard using shanten + uke-ira calculation
- Displays recommendations in a non-intrusive floating panel
- Does not automate play - you remain in control

## Requirements

- macOS 14.0+ (Sonoma)
- Screen Recording permission
- Mahjong Soul running on primary display

## Architecture

Three Swift packages:
- **MahjongCore**: Pure algorithm library (shanten, uke-ira, recommendation logic)
- **MahjongOCR**: Vision framework + template matching + 3-pass aggregation
- **MahjongAdvisorApp**: SwiftUI floating panel + scheduler + UI

## Building

```bash
swift build
```

## Testing

```bash
swift test
```

Note: OCR integration tests require local fixtures and are skipped on CI.

## Distribution

Direct download only (Developer ID signed + notarized). Not available on Mac App Store.

## Documentation

- Design spec: `docs/superpowers/specs/2026-06-06-mahjong-advisor-design.md`
- Implementation plan: `docs/superpowers/plans/2026-06-06-mahjong-advisor.md`
