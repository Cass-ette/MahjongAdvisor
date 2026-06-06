import Foundation

public enum Shanten {
    /// Computes shanten for a 13-tile (or 14-tile with the 14th as the draw) closed hand.
    /// Returns 0 for tenpai, -1 for agari (winning, only for 14-tile 4m+1p or 七対),
    /// positive for tiles away from tenpai.
    /// Considers the standard 4m+1p form, the 七対 (seven pairs) special form,
    /// and 国士無双 (handled separately in its own dedicated shanten).
    public static func compute(closed: [Tile]) -> Int {
        let standard = standardShanten(closed)
        let chiitoitsu = chiitoitsuShanten(closed)
        return min(standard, chiitoitsu)
    }

    /// 七対 (seven pairs) shanten: 6 pairs = tenpai (0), 7 pairs = agari (-1).
    /// Formula: shanten = max(-1, 6 - pair_count).
    /// Note: 七対 requires 7 distinct pairs, so a "quad" (4-of-a-kind) counts
    /// as 1 pair in this formula (cannot form 2 distinct pairs from the same tile).
    private static func chiitoitsuShanten(_ closed: [Tile]) -> Int {
        let counts = tileCounts(closed)
        let pairCount = counts.values.filter { $0 >= 2 }.count
        return max(-1, 6 - pairCount)
    }

    private static func standardShanten(_ closed: [Tile]) -> Int {
        // 1. Count tile occurrences
        let counts = tileCounts(closed)

        // Shanten baseline depends on hand size. For 14-tile hands the
        // ideal is 4m+1p (=8 in the formula), for 13-tile hands the ideal
        // is 3m+1p+2extra (=6). The 13-tile floor is 0 (no agari state),
        // while 14-tile can reach -1.
        let isFourteen = (closed.count == 14)
        let baseline = isFourteen ? 8 : 6
        let floor = isFourteen ? -1 : 0

        var bestShanten = baseline

        // 2. Try every possible head
        for headKey in counts.keys {
            var countsCopy = counts
            guard let headCount = countsCopy[headKey], headCount >= 2 else { continue }
            countsCopy[headKey] = headCount - 2

            let melds = countMelds(countsCopy)
            let shanten = max(floor, baseline - 2 * melds - 1)
            bestShanten = min(bestShanten, shanten)
        }

        // 3. If no head works, try 0-head (no pair)
        let meldsNoHead = countMelds(counts)
        let shantenNoHead = max(floor, baseline - 2 * meldsNoHead)
        bestShanten = min(bestShanten, shantenNoHead)

        return bestShanten
    }

    private static func tileCounts(_ tiles: [Tile]) -> [TileKey: Int] {
        var counts: [TileKey: Int] = [:]
        for tile in tiles {
            let key = TileKey(tile: tile)
            counts[key, default: 0] += 1
        }
        return counts
    }

    /// Counts the maximum number of melds in the given tile counts.
    /// Recursively tries: kan (4 same) → pon (3 same) → chi (3 sequence).
    private static func countMelds(_ counts: [TileKey: Int]) -> Int {
        var counts = counts
        var best = 0
        bestMeldRecurse(counts: &counts, current: 0, best: &best)
        return best
    }

    private static func bestMeldRecurse(counts: inout [TileKey: Int], current: Int, best: inout Int) {
        // Pruning: if even with optimistic remaining, can't beat best
        let remainingTiles = counts.values.reduce(0, +)
        if current + remainingTiles / 3 <= best { return }

        if remainingTiles == 0 {
            best = max(best, current)
            return
        }

        // Pick the smallest tile with count > 0 (sorted order matters: chi
        // can only start at the picked tile's rank, so we must pick the
        // natural smallest to avoid greedily discarding middle tiles of
        // a potential sequence).
        guard let key = smallestPositiveKey(in: counts) else {
            best = max(best, current)
            return
        }

        // Try kan
        if let c = counts[key], c >= 4 {
            counts[key] = c - 4
            bestMeldRecurse(counts: &counts, current: current + 1, best: &best)
            counts[key] = c
        }

        // Try pon
        if let c = counts[key], c >= 3 {
            counts[key] = c - 3
            bestMeldRecurse(counts: &counts, current: current + 1, best: &best)
            counts[key] = c
        }

        // Try chi (only for number suits)
        if key.isNumberSuit, let c = counts[key], c >= 1 {
            let r = key.rank
            if r <= 7,
               let c2 = counts[TileKey(suit: key.suit, rank: r + 1, isRed: false)],
               c2 >= 1,
               let c3 = counts[TileKey(suit: key.suit, rank: r + 2, isRed: false)],
               c3 >= 1 {
                counts[key] = c - 1
                counts[TileKey(suit: key.suit, rank: r + 1, isRed: false)] = c2 - 1
                counts[TileKey(suit: key.suit, rank: r + 2, isRed: false)] = c3 - 1
                bestMeldRecurse(counts: &counts, current: current + 1, best: &best)
                counts[key] = c
                counts[TileKey(suit: key.suit, rank: r + 1, isRed: false)] = c2
                counts[TileKey(suit: key.suit, rank: r + 2, isRed: false)] = c3
            }
        }

        // Try discarding (treating this tile as isolated)
        if let c = counts[key], c >= 1 {
            counts[key] = c - 1
            bestMeldRecurse(counts: &counts, current: current, best: &best)
            counts[key] = c
        }
    }

    /// Returns the smallest TileKey with a positive count. Dictionary
    /// iteration order is not sorted, so we sort explicitly to make the
    /// recursive meld counter deterministic and correct. Honors are
    /// sorted after number tiles, with their enum hash differentiating
    /// white/green/red and the four winds.
    private static func smallestPositiveKey(in counts: [TileKey: Int]) -> TileKey? {
        return counts.keys
            .filter { (counts[$0] ?? 0) > 0 }
            .min { lhs, rhs in
                if lhs.suit != rhs.suit { return lhs.suit.rawValue < rhs.suit.rawValue }
                if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
                // Number tile key vs honor tile key: number tile has honor=nil.
                // We want number tiles to be picked first (since chi works on them).
                switch (lhs.honor, rhs.honor) {
                case (nil, .some): return true
                case (.some, nil): return false
                default: break
                }
                if lhs.honor != rhs.honor { return isHonorLess(lhs.honor, rhs.honor) }
                // Red 5s are "greater" (i.e. non-red first) so the red variant
                // is only picked up after exhausting the non-red.
                return !lhs.isRed && rhs.isRed
            }
    }

    private static func isHonorLess(_ a: Honor?, _ b: Honor?) -> Bool {
        // Both non-nil: order by Honor's natural Comparable (uses synthesized
        // ordering based on the enum cases). White < green < red < wind.
        guard let a, let b else { return false }
        return honorSortValue(a) < honorSortValue(b)
    }

    private static func honorSortValue(_ h: Honor) -> Int {
        switch h {
        case .white: return 0
        case .green: return 1
        case .red:   return 2
        case .wind(let w): return 3 + w.rawValue  // east=4, south=5, west=6, north=7
        }
    }
}

/// Compact key for tile counts in shanten computation.
/// Includes the honor so white/green/red/east/south/west/north don't
/// collapse to the same key (they all have suit=.z, rank=0 otherwise).
struct TileKey: Hashable {
    let suit: Suit
    let rank: Int
    let honor: Honor?
    let isRed: Bool

    init(tile: Tile) {
        self.suit = tile.suit
        self.rank = tile.rank
        self.honor = tile.honor
        self.isRed = tile.isRed
    }

    /// Convenience initializer for number-suit keys (used by chi lookup).
    init(suit: Suit, rank: Int, isRed: Bool) {
        self.suit = suit
        self.rank = rank
        self.honor = nil
        self.isRed = isRed
    }

    var isNumberSuit: Bool { suit.isNumberSuit }
}
