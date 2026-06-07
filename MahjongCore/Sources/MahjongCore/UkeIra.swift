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

    /// Finds effective tiles (uke-ira) for a 13-tile hand.
    /// Returns tiles that would reduce shanten.
    public static func effectiveTiles(
        closed: [Tile],
        ctx: RoundContext,
        redFivesRemaining: [Suit: Int]
    ) -> [UkeIraEntry] {
        guard closed.count == 13 else { return [] }

        let currentShanten = Shanten.compute(closed: closed)
        var effective: [UkeIraEntry] = []

        // Try adding each possible tile
        let allPossibleTiles = generateAllTiles()

        for tile in allPossibleTiles {
            let testHand = closed + [tile]
            let newShanten = Shanten.compute(closed: testHand)

            // If shanten improved, this is an effective tile
            if newShanten < currentShanten {
                let count = countInWall(
                    tile: tile,
                    visible: closed + ctx.discards.flatMap { $0 } + ctx.doraIndicators,
                    redFivesRemaining: redFivesRemaining
                )

                if count > 0 {
                    // Determine wait type (simplified)
                    let waitType = determineWaitType(tile: tile, hand: closed)
                    effective.append(UkeIraEntry(tile: tile, count: count, waitType: waitType))
                }
            }
        }

        return effective
    }

    private static func generateAllTiles() -> [Tile] {
        var tiles: [Tile] = []

        // Number tiles (m, p, s)
        for suit in [Suit.m, Suit.p, Suit.s] {
            for rank in 1...9 {
                tiles.append(Tile(suit: suit, rank: rank))
            }
        }

        // Honor tiles
        tiles.append(Tile(honor: .wind(.east)))
        tiles.append(Tile(honor: .wind(.south)))
        tiles.append(Tile(honor: .wind(.west)))
        tiles.append(Tile(honor: .wind(.north)))
        tiles.append(Tile(honor: .white))
        tiles.append(Tile(honor: .green))
        tiles.append(Tile(honor: .red))

        return tiles
    }

    private static func determineWaitType(tile: Tile, hand: [Tile]) -> WaitType {
        // Simplified wait type detection
        let counts = hand.reduce(into: [Tile: Int]()) { $0[$1, default: 0] += 1 }

        if let count = counts[tile], count == 1 {
            return .tanki  // Single tile wait
        }

        // Default to ryanmen for now (proper detection would be more complex)
        return .ryanmen
    }
}
