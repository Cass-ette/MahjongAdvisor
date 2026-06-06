import Foundation

public struct RoundContext: Sendable, Codable {
    public let discards: [[Tile]]        // 4 players' 牌河
    public let doraIndicators: [Tile]    // 表ドラ
    public let riichiDiscards: [Tile]    // 立直宣言牌

    public init(
        discards: [[Tile]],
        doraIndicators: [Tile],
        riichiDiscards: [Tile]
    ) {
        self.discards = discards
        self.doraIndicators = doraIndicators
        self.riichiDiscards = riichiDiscards
    }
}
