import Foundation

public enum Recommend {
    /// Recommends the best discard and optional riichi declaration.
    /// Returns nil if hand is invalid or no recommendation can be made.
    /// Limited to top 4 recommendations by uke-ira count.
    public static func compute(hand: Hand, ctx: RoundContext) -> [Recommendation] {
        guard hand.closedTiles.count == 14 else { return [] }

        let currentShanten = hand.melds.isEmpty
            ? Shanten.compute(closed: hand.closedTiles)
            : Shanten.computeOpen(hand: hand)

        var candidates: [(Tile, Int, [UkeIraEntry])] = []

        // Try discarding each of the 14 tiles
        for i in 0..<hand.closedTiles.count {
            let discard = hand.closedTiles[i]
            var remaining = hand.closedTiles
            remaining.remove(at: i)

            // Check shanten after discard (should be 13 tiles)
            let shantenAfter = hand.melds.isEmpty
                ? Shanten.compute(closed: remaining)
                : Shanten.computeOpen(hand: Hand(
                    closedTiles: remaining,
                    melds: hand.melds,
                    seatWind: hand.seatWind,
                    roundWind: hand.roundWind,
                    isRiichi: hand.isRiichi,
                    remainingTiles: hand.remainingTiles,
                    redFivesRemaining: hand.redFivesRemaining
                ))

            // Find effective tiles (uke-ira)
            let ukeIra = UkeIra.effectiveTiles(
                closed: remaining,
                ctx: ctx,
                redFivesRemaining: hand.redFivesRemaining
            )

            candidates.append((discard, shantenAfter, ukeIra))
        }

        // Sort by shanten (lower better), then by uke-ira count (higher better)
        candidates.sort { lhs, rhs in
            if lhs.1 != rhs.1 {
                return lhs.1 < rhs.1
            }
            let lhsCount = lhs.2.reduce(0) { $0 + $1.count }
            let rhsCount = rhs.2.reduce(0) { $0 + $1.count }
            return lhsCount > rhsCount
        }

        // Take top 4
        let top = Array(candidates.prefix(4))

        var recommendations: [Recommendation] = []

        for (tile, shanten, ukeIra) in top {
            let reason = "Shanten \(shanten), \(ukeIra.reduce(0) { $0 + $1.count }) uke-ira"
            recommendations.append(.discard(tile: tile, reason: reason, shanten: shanten, ukeIra: ukeIra))
        }

        // Check riichi possibility (if tenpai and not already riichi)
        if currentShanten == 0 && !hand.isRiichi && hand.melds.isEmpty {
            // Riichi: find best discard that maintains tenpai
            if let (tile, ukeIra) = findBestRiichiDiscard(hand: hand, ctx: ctx) {
                recommendations.append(.riichi(discard: tile, ukeIra: ukeIra))
            }
        }

        return recommendations
    }

    private static func findBestRiichiDiscard(hand: Hand, ctx: RoundContext) -> (Tile, [UkeIraEntry])? {
        var bestTile: Tile?
        var bestUkeIra: [UkeIraEntry] = []

        for i in 0..<hand.closedTiles.count {
            let discard = hand.closedTiles[i]
            var remaining = hand.closedTiles
            remaining.remove(at: i)

            let shantenAfter = Shanten.compute(closed: remaining)

            // Must maintain tenpai (shanten 0)
            guard shantenAfter == 0 else { continue }

            let ukeIra = UkeIra.effectiveTiles(
                closed: remaining,
                ctx: ctx,
                redFivesRemaining: hand.redFivesRemaining
            )

            let sum = ukeIra.reduce(0) { $0 + $1.count }
            if bestTile == nil || sum > (bestUkeIra.reduce(0) { $0 + $1.count }) {
                bestTile = discard
                bestUkeIra = ukeIra
            }
        }

        guard let tile = bestTile else { return nil }
        return (tile, bestUkeIra)
    }
}
