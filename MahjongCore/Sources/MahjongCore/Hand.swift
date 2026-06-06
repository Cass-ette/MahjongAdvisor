import Foundation

public struct Hand: Sendable, Codable {
    /// Closed tiles. When 14 tiles present, closedTiles[13] is the most recent draw
    /// and may not be in sort position. closedTiles[0..<13] are sorted by
    /// (suit m < p < s < z, rank 1-9, isRed true < false within 5s).
    /// Invariant: closedTiles.count = 14 - 3 × melds.count (for non-kan melds).
    public var closedTiles: [Tile]
    public var melds: [Meld]
    public var seatWind: Wind
    public var roundWind: Wind
    public var isRiichi: Bool
    public var remainingTiles: Int
    public var redFivesRemaining: [Suit: Int]

    public init(
        closedTiles: [Tile],
        melds: [Meld],
        seatWind: Wind,
        roundWind: Wind,
        isRiichi: Bool,
        remainingTiles: Int,
        redFivesRemaining: [Suit: Int]
    ) {
        self.closedTiles = closedTiles
        self.melds = melds
        self.seatWind = seatWind
        self.roundWind = roundWind
        self.isRiichi = isRiichi
        self.remainingTiles = remainingTiles
        self.redFivesRemaining = redFivesRemaining
    }
}
