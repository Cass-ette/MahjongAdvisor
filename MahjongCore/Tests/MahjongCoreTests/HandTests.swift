import Testing
import Foundation
@testable import MahjongCore

struct HandTests {
    @Test("Closed hand initialization")
    func testClosedHandInit() {
        let tiles = [
            Tile(suit: .m, rank: 1),
            Tile(suit: .m, rank: 2),
            Tile(suit: .m, rank: 3),
            Tile(suit: .p, rank: 4),
            Tile(suit: .p, rank: 5),
            Tile(suit: .p, rank: 6),
            Tile(suit: .s, rank: 7),
            Tile(suit: .s, rank: 8),
            Tile(suit: .s, rank: 9),
            Tile(honor: .wind(.east)),
            Tile(honor: .wind(.south)),
            Tile(honor: .wind(.west)),
            Tile(honor: .white)
        ]
        let hand = Hand(
            closedTiles: tiles,
            melds: [],
            seatWind: .east,
            roundWind: .east,
            isRiichi: false,
            remainingTiles: 70,
            redFivesRemaining: [.m: 1, .p: 1, .s: 1]
        )

        #expect(hand.closedTiles.count == 13)
        #expect(hand.melds.isEmpty)
        #expect(hand.seatWind == .east)
        #expect(hand.roundWind == .east)
        #expect(hand.isRiichi == false)
        #expect(hand.remainingTiles == 70)
    }

    @Test("Open hand with melds")
    func testOpenHand() {
        let closedTiles = [
            Tile(suit: .m, rank: 1),
            Tile(suit: .m, rank: 2),
            Tile(suit: .m, rank: 3),
            Tile(suit: .p, rank: 4),
            Tile(suit: .p, rank: 5),
            Tile(suit: .p, rank: 6),
            Tile(suit: .s, rank: 7),
            Tile(suit: .s, rank: 8),
            Tile(suit: .s, rank: 9),
            Tile(honor: .wind(.east))
        ]
        let pon = Meld(
            kind: .pon,
            tiles: [
                Tile(honor: .wind(.south)),
                Tile(honor: .wind(.south)),
                Tile(honor: .wind(.south))
            ],
            fromPlayer: 1
        )
        let chi = Meld(
            kind: .chi,
            tiles: [
                Tile(suit: .m, rank: 7),
                Tile(suit: .m, rank: 8),
                Tile(suit: .m, rank: 9)
            ],
            fromPlayer: 3
        )

        let hand = Hand(
            closedTiles: closedTiles,
            melds: [pon, chi],
            seatWind: .south,
            roundWind: .east,
            isRiichi: false,
            remainingTiles: 55,
            redFivesRemaining: [:]
        )

        #expect(hand.closedTiles.count == 10)
        #expect(hand.melds.count == 2)
        #expect(hand.melds[0].kind == .pon)
        #expect(hand.melds[1].kind == .chi)
        #expect(hand.seatWind == .south)
    }

    @Test("Red fives remaining default empty")
    func testRedFivesRemainingDefault() {
        let hand = Hand(
            closedTiles: [Tile(suit: .m, rank: 1)],
            melds: [],
            seatWind: .east,
            roundWind: .east,
            isRiichi: false,
            remainingTiles: 70,
            redFivesRemaining: [:]
        )

        #expect(hand.redFivesRemaining.isEmpty)
    }

    @Test("Codable round-trip")
    func testCodableRoundTrip() throws {
        let original = Hand(
            closedTiles: [
                Tile(suit: .m, rank: 1),
                Tile(suit: .p, rank: 5, isRed: true)
            ],
            melds: [
                Meld(
                    kind: .pon,
                    tiles: [
                        Tile(honor: .wind(.east)),
                        Tile(honor: .wind(.east)),
                        Tile(honor: .wind(.east))
                    ],
                    fromPlayer: 2
                )
            ],
            seatWind: .west,
            roundWind: .south,
            isRiichi: true,
            remainingTiles: 42,
            redFivesRemaining: [.m: 0, .p: 0, .s: 1]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Hand.self, from: data)

        #expect(decoded.closedTiles.count == original.closedTiles.count)
        #expect(decoded.melds.count == original.melds.count)
        #expect(decoded.seatWind == original.seatWind)
        #expect(decoded.roundWind == original.roundWind)
        #expect(decoded.isRiichi == original.isRiichi)
        #expect(decoded.remainingTiles == original.remainingTiles)
        #expect(decoded.redFivesRemaining[.s] == 1)
    }
}
