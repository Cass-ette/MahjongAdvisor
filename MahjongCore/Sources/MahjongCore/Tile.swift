import Foundation

public struct Tile: Hashable, Sendable, Codable {
    public let suit: Suit
    public let rank: Int         // 1-9 for m/p/s; 0 for honor
    public let honor: Honor?     // non-nil for 字牌
    public let isRed: Bool       // 赤5 标记; 仅 5m/5p/5s 可能为 true

    public init(suit: Suit, rank: Int, isRed: Bool = false) {
        precondition(
            !isRed || Self.isRedValid(suit: suit, rank: rank),
            "isRed only valid for 5m/5p/5s (got \(suit)\(rank) isRed=true)"
        )
        self.suit = suit
        self.rank = rank
        self.honor = nil
        self.isRed = isRed
    }

    public init(honor: Honor) {
        self.suit = .z
        self.rank = 0
        self.honor = honor
        self.isRed = false
    }

    public static func isRedValid(suit: Suit, rank: Int) -> Bool {
        return suit != .z && rank == 5
    }
}
