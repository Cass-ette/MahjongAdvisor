import Foundation

public enum UkeIra {
    /// Counts how many of `tile` are still in the wall (not in hand/meld/discard/dora).
    /// Handles red 5s correctly: separate count for red 5 vs non-red 5.
    public static func countInWall(
        tile: Tile,
        visible: [Tile],
        redFivesRemaining: [Suit: Int]
    ) -> Int {
        if tile.suit.isNumberSuit && tile.rank == 5 {
            if tile.isRed {
                // Red 5 specifically: only 1 exists at start
                let redVisible = visible.filter { $0 == tile }.count
                let redRemaining = redFivesRemaining[tile.suit] ?? 0
                return max(0, redRemaining - redVisible)
            } else {
                // Non-red 5: 3 exist at start (4 total - 1 red).
                // Count only non-red 5s that are visible
                let nonRedVisible = visible.filter {
                    $0.suit == tile.suit && $0.rank == 5 && !$0.isRed
                }.count
                return max(0, 3 - nonRedVisible)
            }
        } else {
            let visibleCount = visible.filter { $0 == tile }.count
            return max(0, 4 - visibleCount)
        }
    }
}
