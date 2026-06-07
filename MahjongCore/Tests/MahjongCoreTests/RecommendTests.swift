import XCTest
@testable import MahjongCore

final class RecommendTests: XCTestCase {
    func testRecommend_Basic14TileHand() {
        // Simple 14-tile hand
        let closed: [Tile] = [
            Tile(suit: .m, rank: 1), Tile(suit: .m, rank: 2), Tile(suit: .m, rank: 3),
            Tile(suit: .m, rank: 4), Tile(suit: .m, rank: 5), Tile(suit: .m, rank: 6),
            Tile(suit: .m, rank: 7), Tile(suit: .m, rank: 8), Tile(suit: .m, rank: 9),
            Tile(suit: .p, rank: 1), Tile(suit: .p, rank: 1),
            Tile(suit: .s, rank: 5), Tile(suit: .s, rank: 7),
            Tile(suit: .s, rank: 9),  // 14th tile
        ]

        let hand = Hand(
            closedTiles: closed,
            melds: [],
            seatWind: .east,
            roundWind: .east,
            isRiichi: false,
            remainingTiles: 70,
            redFivesRemaining: [.m: 1, .p: 1, .s: 1]
        )

        let ctx = RoundContext(
            discards: [[], [], [], []],
            doraIndicators: [],
            riichiDiscards: []
        )

        let recommendations = Recommend.compute(hand: hand, ctx: ctx)

        // Should get some recommendations
        XCTAssertFalse(recommendations.isEmpty, "Should provide at least one recommendation")
        XCTAssertLessThanOrEqual(recommendations.count, 5, "Should provide at most 5 recommendations (4 discard + 1 riichi)")
    }

    func testRecommend_InvalidHandSize() {
        // 13-tile hand (invalid for recommendation - needs 14)
        let closed: [Tile] = Array(repeating: Tile(suit: .m, rank: 1), count: 13)

        let hand = Hand(
            closedTiles: closed,
            melds: [],
            seatWind: .east,
            roundWind: .east,
            isRiichi: false,
            remainingTiles: 70,
            redFivesRemaining: [:]
        )

        let ctx = RoundContext(
            discards: [[], [], [], []],
            doraIndicators: [],
            riichiDiscards: []
        )

        let recommendations = Recommend.compute(hand: hand, ctx: ctx)

        XCTAssertTrue(recommendations.isEmpty, "Should return empty for invalid hand size")
    }
}
