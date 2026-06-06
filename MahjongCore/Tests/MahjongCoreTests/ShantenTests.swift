import XCTest
@testable import MahjongCore

final class ShantenTests: XCTestCase {
    /// 13-tile hand, no pair, 0 melds → 8 - 0 - 0 = 8 shanten? No, wait.
    /// Standard formula: shanten = 8 - 2*meld_count - pair_flag
    /// For 13 tiles: shanten = 8 - 2*m - p, capped at 8.
    /// For 14 tiles: shanten = 8 - 2*m - p, capped at -1 (agari).

    func testShantenRandomChaos() {
        // 13 random disconnected tiles: high shanten
        let hand: [Tile] = [
            Tile(suit: .m, rank: 1), Tile(suit: .m, rank: 4),
            Tile(suit: .m, rank: 7), Tile(suit: .p, rank: 2),
            Tile(suit: .p, rank: 5), Tile(suit: .p, rank: 8),
            Tile(suit: .s, rank: 3), Tile(suit: .s, rank: 6),
            Tile(suit: .s, rank: 9), Tile(honor: .white),
            Tile(honor: .green), Tile(honor: .red),
            Tile(honor: .wind(.east)),
        ]
        let shanten = Shanten.compute(closed: hand)
        XCTAssertGreaterThanOrEqual(shanten, 6, "Random 13 tiles should have very high shanten")
    }

    func testShantenPerfectMeldHand() {
        // 3 melds + 1 pair (13 tiles) → shanten = 0 (tenpai)
        let tenpai: [Tile] = [
            Tile(suit: .m, rank: 1), Tile(suit: .m, rank: 2), Tile(suit: .m, rank: 3),
            Tile(suit: .m, rank: 4), Tile(suit: .m, rank: 5), Tile(suit: .m, rank: 6),
            Tile(suit: .m, rank: 7), Tile(suit: .m, rank: 8), Tile(suit: .m, rank: 9),
            Tile(honor: .wind(.east)), Tile(honor: .wind(.east)),
            Tile(suit: .p, rank: 5), Tile(suit: .p, rank: 8),
        ]
        XCTAssertEqual(tenpai.count, 13)
        let shanten = Shanten.compute(closed: tenpai)
        XCTAssertEqual(shanten, 0, "3 melds + 1 pair + 2 dead tiles = tenpai")
    }

    func testShantenOneAway() {
        // 1-shanten hand: 2 melds + 1 pair + 5 dead tiles = 1 shanten
        let oneShanten: [Tile] = [
            Tile(suit: .m, rank: 1), Tile(suit: .m, rank: 2), Tile(suit: .m, rank: 3),
            Tile(suit: .m, rank: 4), Tile(suit: .m, rank: 5), Tile(suit: .m, rank: 6),
            Tile(honor: .wind(.east)), Tile(honor: .wind(.east)),
            Tile(suit: .p, rank: 2), Tile(suit: .p, rank: 5), Tile(suit: .p, rank: 8),
            Tile(suit: .s, rank: 1), Tile(suit: .s, rank: 4),
        ]
        XCTAssertEqual(oneShanten.count, 13)
        let shanten = Shanten.compute(closed: oneShanten)
        XCTAssertEqual(shanten, 1, "2 melds + 1 pair + 5 dead tiles = 1 shanten")
    }
}
