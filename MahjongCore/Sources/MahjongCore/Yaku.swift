import Foundation

public enum Yaku {
    /// Returns possible yaku tags for a hand.
    /// Simplified implementation: returns basic yaku possibilities.
    public static func possibilities(hand: Hand) -> [String] {
        var yaku: [String] = []

        // Riichi
        if hand.isRiichi {
            yaku.append("riichi")
        }

        // Tanyao (all simples: no terminals/honors)
        let hasTerminalsOrHonors = hand.closedTiles.contains { tile in
            tile.suit == .z || tile.rank == 1 || tile.rank == 9
        }
        if !hasTerminalsOrHonors && hand.melds.allSatisfy({ meld in
            meld.tiles.allSatisfy { $0.suit != .z && $0.rank != 1 && $0.rank != 9 }
        }) {
            yaku.append("tanyao")
        }

        // Pinfu (all sequences, no value pair)
        if hand.melds.isEmpty {
            // Simplified: assume pinfu is possible if no honors in hand
            let hasHonors = hand.closedTiles.contains { $0.suit == .z }
            if !hasHonors {
                yaku.append("pinfu")
            }
        }

        // If no specific yaku, return empty (no yaku = invalid hand for winning)
        return yaku.isEmpty ? [] : yaku
    }
}
