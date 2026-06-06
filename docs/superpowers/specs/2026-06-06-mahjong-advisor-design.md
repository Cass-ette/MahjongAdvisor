# MahjongAdvisor — Design Spec

**Date**: 2026-06-06
**Status**: Draft (post-brainstorming, post-1st-review-revision, pre-implementation)
**Platform**: macOS 14.0+ (Sonoma) · SwiftUI native
**Distribution**: Direct download (Developer ID signed + notarized). **Not** App Store.

## 1. Purpose

A macOS desktop advisor for Japanese riichi mahjong (Mahjong Soul / 雀魂). It observes a running Mahjong Soul window, OCRs the hand and table state, computes the best discard (and an optional riichi declaration) using shanten + uke-ira calculation, and displays the recommendation in a small floating panel next to the game. **It does not automate play** — the human remains the decision-maker; the tool is a coach / second brain.

## 2. Out of Scope

- Automated play (clicking tiles, sending inputs to the game)
- Online play / account interaction / scraping the Mahjong Soul API
- 3-player mahjong, non-riichi variants, American mahjong
- Multi-window support (only one Mahjong Soul window tracked)
- Multi-display: Mahjong Soul window must be on the **primary display** in v1
- iOS / iPadOS / Windows / Linux
- Mac App Store distribution
- Cloud sync, account system, telemetry
- Universal wild cards / jokers ("赖子" / 百搭) — **not in v1**; only 赤宝牌 red fives are supported
- Ankan / kakan / pon / pass recommendations in the v1 enum (algorithm returns only `discard` and `riichi`)

## 3. Supported Rules (v1)

- **Players**: 4
- **Round**: East-only (東場)
- **Dora**: 表ドラ visible indicator + 赤宝牌 (1 red 5 in each of 萬/筒/索)
- **Yaku (algorithmically considered)**: riichi, tanyao, yakuhai (三暗刻 / 役牌), honitsu, chinitsu. (Yaku enumeration is partial — see §6.5.)
- **No** support yet for: 三人 (3-player), 半庄, special event rules, 裏ドラ (hidden, only revealed post-riichi), 一発

## 4. User Experience

### 4.1 Lifecycle

1. User launches `MahjongAdvisor.app`.
2. App requests **Screen Recording** permission (one-time, system-prompted). If denied, panel shows guidance; no OCR runs.
3. App scans `CGWindowListCopyWindowInfo` for "雀魂" / "Mahjong Soul" / "Majsoul". If found and on the primary display, attach; else show "未检测到雀魂" and idle.
4. App polls the game window **every 3 seconds** (user-configurable 1-10s in `SettingsView`).
5. Each poll: capture (ScreenCaptureKit) → OCR → MahjongCore.recommend → update floating panel.
6. The floating panel is draggable; its position is persisted.
7. Menu bar icon: Pause (`⌘⇧P`), Hide Panel, Recalibrate Layout, Settings, Quit (`⌘Q`).
8. The app can be paused (toggle via menu bar or `⌘⇧P`) — paused state shows "已暂停" and skips polls.

### 4.2 Floating Panel — Collapsed

A small panel (~280×80pt) pinned to one corner of the Mahjong Soul window. Contents:

- **Top line**: `推荐：打 5m  ·  向听 0  ·  3 种听牌`
- **Bottom line**: `赤5:有  宝牌:7p  ·  置信度: 92%` (one-line status)
- **Right corner icon** (SF Symbols): OCR status — `checkmark.circle.fill` / `exclamationmark.triangle.fill` / `xmark.circle.fill`
- **Status hint** (when paused or in lobby): "已暂停" or "请进入对局"

### 4.3 Floating Panel — Expanded

Click anywhere on the collapsed panel → expand (~520×400pt) showing:

- Hand tiles (with the recommended discard highlighted in red)
- Melds / open sets
- 牌河 (all 4 players' discards, read-only)
- Dora indicator + red-fives count
- uke-ira list (effective tiles for the recommended discard, with count and wait type)
- **修正** button (enters Edit Mode)
- Confidence per region (hand / 牌河 / dora)

### 4.4 Edit Mode (OCR correction)

Entered via:
- Click **修正** in expanded panel
- Press **⌘⇧E** (global hotkey; hardcoded, not configurable in v1)
- **Auto-triggered** if `ConfidenceMap.hand < 0.7` OR `ConfidenceMap.dora < 0.7`

#### 4.4.1 The "no focus theft" problem and resolution

**Problem**: `.nonactivatingPanel` does not receive keyboard events. A pure global hotkey for tile editing would require the panel to receive keys (←/→, 1-9, M/P/S/Z, Esc).

**Resolution**:
- The panel uses `NSPanel` with `.nonactivatingPanel` style for **mouse** interactions (clicks, drags don't steal focus from Mahjong Soul).
- For **keyboard** input in Edit Mode, the app installs an `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` handler while edit mode is active. This handler:
  1. Intercepts keys when the panel is visible
  2. Transforms them into tile-editing actions
  3. **Returns `nil`** to swallow the key event so it never reaches Mahjong Soul
  4. Tracks an `EditSession.cursor` for the current focused tile slot
- The first time Edit Mode is entered, the user sees a small banner: "正在编辑手牌 (按 Esc 退出)" so they know keystrokes are being captured.
- To exit: `Esc`, the **✓ 确认** button, mouse leaves panel for > 3s, or next OCR cycle confirms the hand with confidence ≥ 0.7.

#### 4.4.2 Three parallel correction paths (drag removed for v1)

| Path | Trigger | Steps | Time-to-fix |
|---|---|---|---|
| **Hotkey flow** | `⌘⇧E` enters edit mode; `←/→` move cursor, `1-9` change rank, `M/P/S/Z` switch suit, `Esc` exit | 1-2 keystrokes | ~1s |
| **Click** | Click any wrong tile → 34-tile popover (`LazyVGrid` of `TileCell`) → click correct | 2 clicks | ~2s |
| **AI candidates** | The same 3-pass OCR runs every cycle; uncertain tiles (any pass disagreeing with confidence < 0.6) get a `❓` marker in the expanded view → click expands Top-3 candidates from the 3 passes → click picks | 1-2 clicks | ~1.5s |

**Mutual exclusion**: A single `EditSession` state object holds `activePath: Path?`. Only one path can be active at a time; the others are suppressed while one is in flight. (Avoids collisions like "click popover open + drag in progress".)

#### 4.4.3 Exit behavior

- `Esc` or **✓ 确认** button: commit current Hand, exit edit mode.
- **Mouse leaves panel for > 3s**: **auto-save** the partially-corrected Hand (do **not** discard), exit edit mode, but next OCR cycle may re-trigger edit mode if confidence still < 0.7.
- **Next OCR cycle confirms** with confidence ≥ 0.7: exit edit mode silently; the corrected Hand is now what OCR also reports.

### 4.5 Recalibrate Layout

Menu bar → "校准窗口布局" walks the user through clicking 5 anchor points (top-left of hand, bottom-right of hand, top-left of 牌河, dora area, meld area). Stored as **relative percentages of the window bounds** (so DPI / resolution scaling is automatic). Triggers a "请重新进入对局以应用新布局" reminder; calibration takes effect on the next OCR cycle.

Layout coordinates live in `~/Library/Application Support/MahjongAdvisor/layout.json`. If overall OCR confidence drops below 0.5 for > 2 consecutive cycles, the app shows: "OCR 似乎失效，请重新校准窗口布局".

## 5. Architecture

### 5.1 Module Map

| Module | Type | Responsibility | Depends on |
|---|---|---|---|
| `MahjongCore` | Swift Package, library | Tile/Hand/Meld/Wind/Honor model, rules, shanten, uke-ira, recommend | nothing |
| `MahjongOCR` | Swift Package, library | Window enumeration, screen capture, Vision OCR + template matching, 3-pass candidate generation | `MahjongCore` (for `Tile` / `Hand` types) |
| `MahjongAdvisorApp` | SwiftUI App | Floating panel UI, edit mode, key interceptor, settings, scheduling | `MahjongCore`, `MahjongOCR` |
| `MahjongCoreTests` | XCTest target | Unit tests for `MahjongCore` | `MahjongCore` |
| `MahjongOCRTests` | XCTest target | Local-only integration tests with screenshot fixtures | `MahjongCore`, `MahjongOCR` |

All packages live in a single Swift workspace under one git repo.

### 5.2 Data Flow

```
┌────────────────┐
│ Mahjong Soul   │  (game window, primary display only)
│ window         │
└────────┬───────┘
         │  CGWindowListCopyWindowInfo → find by title
         │  ScreenCaptureKit SCScreenshotManager → screenshot (3s interval, skip-if-busy)
         ▼
┌────────────────┐
│ MahjongOCR     │
│  - Region crop │  (hand, 牌河, dora — relative % coordinates)
│  - 3 passes:   │
│    (a) raw      │  Vision VNRecognizeTextRequest
│    (b) bin.     │  thresholded binarization → VNRecognizeTextRequest
│    (c) edge     │  edge-enhanced → template matcher
│  - Aggregate:  │  (a)+(b)+(c) → per-slot confidence
│                │  agreement = avg, disagreement = Top-3 candidates
└────────┬───────┘
         │  OCRResult (Hand + 牌河 + dora + redFivesRemaining + ConfidenceMap + per-tile candidates)
         ▼
┌────────────────┐
│ MahjongCore    │
│  - Validate    │  (immutable; throws → caller maps to []  return)
│  - Compute     │  shanten, uke-ira
│  - Recommend   │  best discard + reason
└────────┬───────┘
         │  [Recommendation] (≤ 4: 1 primary discard, ≤ 2 alt discards, ≤ 1 riichi)
         ▼
┌────────────────┐
│ MahjongAdvisor │  SwiftUI floating panel renders
│  App           │  collapsed / expanded / edit-mode
└────────────────┘
```

### 5.3 Concurrency & lifecycle

- **Polling**: `OCRScheduler` runs a single long-lived `Task`. Sleeps `pollIntervalSeconds` (from `config.json`, default 3s) between calls. **Skip-if-busy**: if a previous cycle is still running, skip the next tick (do not queue).
- **Each cycle** is tagged with a monotonic `cycleId: UInt64`. Stale results (whose cycleId no longer matches the current one) are discarded on the MainActor.
- **OCR** runs at `TaskPriority.background`.
- **MahjongCore.compute** runs on a background actor.
- **UI updates** marshalled to MainActor.
- All `MahjongCore` types are `Sendable`.
- **Edit in progress**: if user starts editing while OCR is mid-flight, OCR's result for that cycle is **discarded** (the user's edit wins for that cycle).
- **Lobby detection**: 3 consecutive cycles returning `parseFailure` → enter lobby state (`"请进入对局"`) and pause polling until hand parses successfully again.

### 5.4 Key Types (`MahjongCore`)

```swift
enum Suit: String, Sendable, Codable, Hashable { case m, p, s, z }

enum Wind: Int, Sendable, Codable, Hashable {
  case east = 1, south, west, north
  // 0/5/6/7 reserved for dragons
}

enum Honor: Sendable, Codable, Hashable {
  case wind(Wind)
  case white, green, red   // 白 / 發 / 中
}

struct Tile: Hashable, Sendable, Codable {
  let suit: Suit
  let rank: Int        // 1-9 for m/p/s; rank is ignored when honor is set
  let honor: Honor?    // non-nil for 字牌
  let isRed: Bool      // 赤5 标记；仅 5m/5p/5s 可能为 true

  init(suit: Suit, rank: Int, isRed: Bool = false) {
    precondition(!(isRed && (suit == .z || rank != 5)), "isRed only valid for 5m/5p/5s")
    self.suit = suit
    self.rank = rank
    self.honor = nil
    self.isRed = isRed
  }

  init(honor: Honor) {
    self.suit = .z
    self.rank = 0
    self.honor = honor
    self.isRed = false
  }
}

struct Meld: Sendable, Codable, Hashable {
  enum Kind: Sendable, Codable, Hashable { case pon, chi, kan(closed: Bool) }
  let kind: Kind
  let tiles: [Tile]    // 4 for kan, 3 otherwise
  let fromPlayer: Int? // 暗杠: nil
}

struct Hand: Sendable, Codable {
  /// Closed tiles. When 14 tiles present, the 14th tile (closedTiles[13]) is the
  /// most recently drawn tile; it is the most likely discard on the user's next action.
  /// The first 13 tiles are **sorted** by (suit m < p < s < z, rank 1-9, isRed true < false
  /// within 5s); the 14th (draw) may not be in sort position.
  /// Invariant: closedTiles.count = 14 - 3 × melds.count (for non-kan melds; subtract 1 more per kan).
  var closedTiles: [Tile]
  var melds: [Meld]
  var seatWind: Wind
  var roundWind: Wind
  var isRiichi: Bool
  var remainingTiles: Int       // 牌山剩余; for UI + wall capacity
  /// Per-suit count of red 5s still in the wall (max 1 per suit at start).
  /// Decremented whenever a red 5 is observed in hand/meld/discard/doraIndicators.
  var redFivesRemaining: [Suit: Int]
  
  // Hand is a value-type snapshot; `recommend` does not mutate its input.
}

struct RoundContext: Sendable, Codable {
  let discards: [[Tile]]        // 4 players' 牌河
  let doraIndicators: [Tile]    // 表ドラ (visible)
  let riichiDiscards: [Tile]    // 立直宣言牌 (for furiten / 振听判定)
}

enum Recommendation: Sendable, Codable {
  /// Best discard; ≤ 1 primary + ≤ 2 alternatives in the returned array.
  case discard(tile: Tile, reason: String, shanten: Int, ukeIra: [UkeIraEntry])
  /// Suggested riichi declaration; only when closed, tenpai, and bank ≥ 1000.
  /// `ukeIra` included so UI can show "立直 → 打 X · N 种听牌".
  case riichi(discard: Tile, ukeIra: [UkeIraEntry])
}

struct UkeIraEntry: Sendable, Codable {
  let tile: Tile
  let count: Int           // 剩余枚数 in wall
  let waitType: WaitType
}

enum WaitType: String, Sendable, Codable {
  case ryanmen, kanchan, penchan, tanki, toitsu, shanpon
}

enum MahjongError: Error, Sendable {
  case handSizeInvalid(Int)
  case tileCountOverflow(Tile, count: Int)    // e.g. 5 of the same tile
  case unsupportedRule(String)
  case parseFailure(String)
  case ocrLowConfidence(region: String, score: Double)
}

/// Returns ≤ 4 entries: 1 primary discard, ≤ 2 alternative discards,
/// ≤ 1 riichi (when applicable). Returns `[]` (not throw) on invalid hand;
/// the AppState layer maps `[]` to "Hand unparseable, please re-enter".
func recommend(hand: Hand, ctx: RoundContext) -> [Recommendation]
```

> **Note on doraIndicators**: it lives on `RoundContext` only (round-level state, not hand-level). `Hand` does not have a `doraIndicators` field.

### 5.5 Key Types (`MahjongOCR`)

```swift
struct OCRResult: Sendable {
  var handTiles: [Tile]?           // nil = "couldn't parse" (treated as unparseable)
  var melds: [Meld]?
  var discards: [[Tile]]?          // 4 players
  var doraIndicators: [Tile]?
  var redFivesRemaining: [Suit: Int]
  var confidence: ConfidenceMap
  /// Per-slot top-3 candidates from the 3-pass OCR.
  /// Always present, even when handTiles is not nil (lets the UI show ❓ markers).
  var handTileCandidates: [[HandTileCandidate]]
}

struct HandTileCandidate: Sendable {
  let tile: Tile
  let confidence: Double
}

struct ConfidenceMap: Sendable {
  var hand: Double          // 0-1; triggers Edit Mode if < 0.7
  var discard: Double
  var dora: Double          // triggers Edit Mode if < 0.7
  /// overall = min(hand, discard, dora) — used for the "OCR seems broken" banner.
  var overall: Double { min(hand, discard, dora) }
}

protocol OCREngine: Sendable {
  func recognize(screenshot: CGImage,
                 windowBounds: CGRect,
                 layout: LayoutTemplate) async throws -> OCRResult
}

/// Layout coordinates stored as **percentages** of the window bounds.
struct LayoutTemplate: Codable, Sendable {
  var handRect: CGRect          // 0-1 normalized
  var meldRect: CGRect
  var discardRects: [CGRect]    // 4 rects
  var doraRect: CGRect
}
```

The default `OCREngine` is `VisionOCREngine`, which:
1. Crops the screenshot to `LayoutTemplate` sub-rectangles (DPI-independent).
2. Runs **three preprocessing passes** per region:
   - **(a) raw**: image as-is → `VNRecognizeTextRequest`
   - **(b) binarized**: Otsu threshold → `VNRecognizeTextRequest`
   - **(c) template**: hand and 牌河 use a tile-image template matcher (small fixed graphics — OCR works poorly on these)
3. **Aggregates** per slot:
   - If 2+ passes agree (each ≥ 0.6 confidence) → tile is confirmed, confidence = average.
   - If passes disagree → top 3 candidates surfaced with confidences; slot marked `❓` (any confidence < 0.7 also marks `❓`).
4. UI shows `❓` on slots that the user can click to expand Top-3 (the AI candidate path).

### 5.6 Key Components (`MahjongAdvisorApp`)

| Component | Type | Responsibility |
|---|---|---|
| `AppDelegateAdaptor` | `NSApplicationDelegate` (used via `@NSApplicationDelegateAdaptor`) | Menu bar (`NSStatusItem`), hotkey registration, lifecycle |
| `WindowTracker` | `actor` (NOT `@MainActor`; offloads `CGWindowListCopyWindowInfo`) | Scans for Mahjong Soul window; publishes via `AsyncStream<WindowBounds?>` to MainActor |
| `OCRScheduler` | `@MainActor` class | 3-second timer (skip-if-busy), `cycleId` tagging, dispatches to `OCREngine` |
| `KeyInterceptor` | `NSObject` | Installs `NSEvent.addLocalMonitorForEvents` while Edit Mode is active; returns `nil` to swallow keys |
| `FloatingPanel` | `NSPanel` subclass | `.nonactivatingPanel`, `HUD` window level, `isMovableByWindowBackground = true`; collapsed: drag-on-background; expanded: drag-on-title-only |
| `PanelContentView` | SwiftUI view | Collapsed / expanded / edit-mode rendering |
| `HandEditorView` | SwiftUI view | Edit mode UI (3 paths via `EditSession` state object) |
| `SettingsView` | SwiftUI view | Polling interval slider (1-10s), log level picker |
| `AppState` | `@Observable` class | Top-level state: `OCRResult?`, `Recommendation`, `mode` (`.collapsed` / `.expanded` / `.editing` / `.paused` / `.lobby`) |

## 6. Algorithm — `MahjongCore.recommend`

### 6.1 Shanten calculation

For a 14-tile hand, compute minimum tiles to tenpai (向听 0) and tiles to win (向听 -1 / 和了). Enumerates:

1. **Standard form (4m + 1p)**: For each candidate head, find the best decomposition of the remaining tiles into melds (三张顺/刻).
2. **七对 (7 pairs)**: Special form, treated separately.
3. **国士無双 (13 orphans)**: Treated separately.
4. **Open hand (副露)**: For hands with `m melds`, only the closed tiles are decomposed into `(4 - m)` melds + 1 pair. Meld tiles are fixed (cannot be discarded).

Constant-time in practice (n=14); per-call cost is on the order of thousands of tile-type operations, well under 1ms.

### 6.2 uke-ira (effective tiles)

For each candidate discard `d` from a 14-tile hand:
1. Compute the resulting 13-tile shanten.
2. Find all `t` such that adding `t` reduces shanten by 1.
3. For each such `t`, compute `count_in_wall(t)`:
   ```
   visible(t) = count of t in closedTiles + melds + discards + doraIndicators
   
   // For 5m/5p/5s, handle red-5 separately (1 red + 3 normal in wall at start):
   if t.suit is .m/.p/.s && t.rank == 5 {
     if t.isRed {
       // Query is for the red 5 specifically (only 1 exists):
       available = redFivesRemaining[t.suit] ?? 0
     } else {
       // Query is for non-red 5s (3 exist at start):
       // visible_nonred = count of non-red 5s in visible(t)
       // For simplicity, approximate: visible(t) includes both red and non-red;
       // we know at most 1 of visible(t) is red, so visible_nonred ≈ visible(t) - (1 - redFivesRemaining).
       // Correct formula: available = (3 - visible_nonred)
       //                            = 3 - (visible(t) - (1 - redFivesRemaining[t.suit]))
       //                            = 4 - visible(t) - 1 + redFivesRemaining[t.suit]
       redRemaining = redFivesRemaining[t.suit] ?? 1
       available = max(0, 3 - visible(t) + (1 - redRemaining))
     }
   } else {
     available = max(0, 4 - visible(t))
   }
   return available
   ```

### 6.3 Recommendation ranking

Rank candidates by:
1. **Lower shanten first** (0 > 1 > 2 > ...)
2. **Within same shanten**: higher `sum(ukeIra.count)` (total effective tiles)
3. **Within same**: prefer uke-ira of `waitType = ryanmen` (safer/more common) — weighted by tile count
4. **Within same**: prefer discards that are **not** ドラ / 赤牌 (don't toss bonus tiles)
5. **Yaku penalty** (see §6.5): if 0-shanten and the hand has only one viable yaku, penalize discards that break that yaku
6. **Tie-break**: tile code alphabetical (deterministic)

**"Early vs late game" flip removed** for v1. The single rule is: when shanten is unchanged, prefer not discarding ドラ/赤. (A future v2 can add a turn-based flip.)

### 6.4 Special decisions

For v1, only `Recommendation.discard` and `Recommendation.riichi` are returned.

- **Riichi**: when `isRiichi == false` AND `shanten == 0` AND `remainingTiles >= 4` AND closed (no melds), return a `riichi(discard:, ukeIra:)` entry alongside the primary discard. If the primary discard is the same as the riichi discard, the riichi entry is omitted (the user already has the discard advice).
- **Ankan / kakan / pon**: out of scope for v1. Reserved for v2. (Removed from the enum in v1; see §2.)

### 6.5 Yaku penalty (v1, partial)

The algorithm maintains a `yakuPossibilities: Set<YakuTag>` for the hand. For v1, the tags considered are: `tanyao`, `yakuhai`, `honitsu`, `chinitsu`, `riichi`. (No 役満 in v1.)

When `shanten == 0` and `yakuPossibilities.count == 1`, the lone yaku is added to the ranker as a constraint: prefer discards that **do not** break it. The check is:

- `tanyao` is preserved iff all closed tiles and meld tiles are simples (no terminals, no honors).
- `yakuhai` (役牌) is preserved iff at least one of the player's seat-wind / round-wind / dragon pair is intact.
- `honitsu` / `chinitsu` is preserved iff the hand is ≥ half one suit (for honitsu) or all one suit (for chinitsu).

Full yaku enumeration is **v2**; v1 only applies the penalty on 0-shanten, single-yaku hands.

## 7. Error Handling

| Situation | Behavior |
|---|---|
| Screen Recording permission denied | "请在 系统设置→隐私与安全性→录屏 中授权 MahjongAdvisor"; idle until granted |
| No Mahjong Soul window on primary display | Panel shows "未检测到雀魂"; idle until found |
| Window on non-primary display | "请将雀魂窗口移至主屏幕"; idle (multi-display is v2) |
| Window found but obscured (covered) | "游戏窗口被遮挡"; idle until visible |
| `ConfidenceMap.hand < 0.7` OR `.dora < 0.7` | Auto-enter Edit Mode for that region; show `exclamationmark.triangle.fill` on the panel |
| 3 consecutive parse failures | Lobby state: "请进入对局"; pause polling |
| Hand parse produces invalid composition (e.g., 5 of same tile) | `MahjongError.tileCountOverflow`; panel shows "手牌识别异常，请手动修正"; auto-edit |
| Hand parse size invalid (≠ 13-3k closed tiles) | `MahjongError.handSizeInvalid`; same as above |
| `recommend` validation fails | Return `[]` (not throw); AppState maps to "Hand unparseable, please re-enter" |
| OCR returns different hands on consecutive frames (likely animation) | Hold previous result; flag "牌局可能切换中" until 2 consecutive matches |
| OCR overall confidence < 0.5 for > 2 cycles | "OCR 似乎失效，请重新校准窗口布局" banner |
| App paused | "已暂停" in panel; no OCR; `⌘⇧P` to resume |

## 8. Testing Strategy

### 8.1 `MahjongCore` — Unit Tests (50+ cases)

- Tile model: equality, red-five init guard, encoding round-trip
- Shanten: standard hands (1-shanten, tenpai, agari), 七对, 国士無双
- Shanten: **open hand (副露)** decomposition
- Shanten: 赤5 计入: 4赤5万, 3赤5万 + 1普通5万, 0赤5万
- Shanten: 13-orphans wait
- uke-ira: 両面/坎張/辺張/単騎 fixtures
- uke-ira: red-five adjustment formula (`redFivesRemaining`)
- Recommendation: best discard for known fixtures (10+)
- RoundContext: 牌河 affects uke-ira counting
- Edge cases: 流局 (no draw), 立直后, 一発判定 (placeholder), 振听
- Yaku penalty: 0-shanten single-yaku preservation

### 8.2 `MahjongOCR` — Integration Tests (5-10 fixtures, **local only**)

- Screenshots saved to `Tests/Fixtures/` (committed; scrubbed via `scripts/redact.py` which masks player names / avatars / match history)
- For each: known expected hand, melds, 牌河, dora; assert parse succeeds and matches
- Confidence scoring: a hand-crafted "noisy" screenshot triggers Edit Mode
- **CI**: these tests are **skipped on CI** (no `CGWindowListCopyWindowInfo` / `ScreenCaptureKit` in headless runners). Run locally via `swift test --filter OCR`.
- Tests assert on `OCRResult` (raw, including `handTileCandidates`); a separate test runs `OCRResult → Hand` parsing via `MahjongCore`. This keeps Core tests independent of OCR fixtures.

### 8.3 App — Manual Smoke Tests

- Permission flow on first launch
- Drag the floating panel; restart and verify position persisted
- Edit Mode: all 3 paths converge to same `Hand`
- KeyInterceptor: keys intercepted only while Edit Mode active; otherwise pass through
- Quit / relaunch; verify state restored
- Pause / resume via `⌘⇧P`
- Recalibrate layout flow

## 9. Configuration & Persistence

Stored in `~/Library/Application Support/MahjongAdvisor/`:

```
config.json:
{
  "pollIntervalSeconds": 3,        // 1-10, default 3
  "panelPosition": {"x": 100, "y": 200},
  "panelMode": "collapsed",        // collapsed | expanded
  "logLevel": "info"               // debug | info | warn | error
}

layout.json:                        // LayoutTemplate; calibratable
{
  "handRect":        {"x": 0.05, "y": 0.75, "w": 0.60, "h": 0.10},
  "meldRect":        {...},
  "discardRects":    [...],
  "doraRect":        {...}
}
```

Logs: `os.Logger` (subsystem `com.example.MahjongAdvisor`) → Console.app + `~/Library/Logs/MahjongAdvisor/app.log` (rotated at 10MB).

Hardcoded (not in config): hotkey `⌘⇧E` for Edit Mode, hotkey `⌘⇧P` for Pause, theme = system.

## 10. Permissions & Distribution

- **Distribution**: Direct download only. Developer ID signed + Apple notarized. **Not** Mac App Store (sandboxing rules would block `CGWindowListCopyWindowInfo` of other apps' windows).
- **Entitlements** (Hardened Runtime):
  - `com.apple.security.cs.allow-jit` — not needed (no JIT)
  - `com.apple.security.cs.disable-library-validation` — not needed
  - **Screen capture**: use `ScreenCaptureKit` (macOS 12.3+) — works under Hardened Runtime; user must grant Screen Recording permission in System Settings.
- **Code signing**: `Developer ID Application: <Team Name> (<TEAMID>)`.
- **Privacy manifest** (`PrivacyInfo.xcprivacy`): declare `NSPrivacyAccessedAPICategoryUserDefaults` (config persistence) and `NSPrivacyAccessedAPICategoryFileTimestamp` (log file access).

## 11. Open Questions / Future Work

- **3-player and other rules**: blocked on user request, not a v1 priority.
- **Universal wild cards (万能牌 / 赖子)**: needs explicit user request and rule spec; current data model has no slot for it. **Note**: 赖子 (lài zi) is the standard Chinese term for wild card / joker — distinct from 赤宝牌.
- **Multi-display**: panel position math needs validation across displays (v1 assumes primary).
- **CJK font in panel**: tile codes in expanded view use system monospaced font; red-5 tiles use a red-tinted background. No custom PNG assets in v1.
- **Onboarding tutorial**: skip for v1.
- **Telemetry / usage analytics**: explicitly excluded.
- **Localization**: panel UI in zh-Hans for v1.
- **Ankan / kakan / pon recommendations**: v2; re-add to `Recommendation` enum with clear migration diff.
- **Drag edit path**: v2 (when SwiftUI `.draggable` / `.dropDestination` ergonomics for `.nonactivatingPanel` are validated).
- **Configurable hotkeys / themes**: v2 (requires hotkey-capture UI and theme system).

## 12. Glossary

- **手牌 (てぱい / shǒupái)**: closed hand tiles
- **向听 (シャンテン / xiàngtīng)**: tiles away from tenpai; 0 = tenpai, -1 = winning
- **听牌 (テンパイ / tīngpái)**: ready hand, one tile from winning
- **牌河 (はいが / páihé)**: discard pile
- **ドラ (dora)**: bonus tile; **表ドラ** (omote) = visible indicator; **裏ドラ** (ura) = hidden, revealed post-riichi (v1 ignores ura)
- **赤ドラ (akadora / 赤宝牌)**: red five dora — one each of 5m/5p/5s; v1's only "special tile"
- **立直 (リーチ / lìzhí)**: riichi declaration
- **副露 (ふろ / fùlù)**: open meld (pon/chi/kan)
- **振听 (フリテン / zhèntīng)**: temporary furiten, no ron allowed
- **赖子 (lài zi)**: colloquial Chinese for **wild card / joker tile** — **out of scope in v1**
- **Tile code notation**: 1m-9m (萬), 1p-9p (筒), 1s-9s (索), 1z-7z (字, ordered 东南西北白發中). The 14th closed tile (when present) is the most recent draw.
