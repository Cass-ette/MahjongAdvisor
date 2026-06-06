import XCTest
@testable import MahjongCore

final class RoundContextTests: XCTestCase {
    func testInit() {
        // Arrange: Create sample discards for 4 players
        let player0Discards = [
            Tile(suit: .m, rank: 1),
            Tile(suit: .p, rank: 2)
        ]
        let player1Discards = [
            Tile(suit: .s, rank: 3)
        ]
        let player2Discards: [Tile] = []
        let player3Discards = [
            Tile(suit: .m, rank: 9),
            Tile(suit: .p, rank: 8),
            Tile(suit: .s, rank: 7)
        ]
        let discards = [player0Discards, player1Discards, player2Discards, player3Discards]

        let doraIndicators = [
            Tile(suit: .m, rank: 5),
            Tile(honor: .wind(.east))
        ]

        let riichiDiscards: [Tile] = []

        // Act
        let context = RoundContext(
            discards: discards,
            doraIndicators: doraIndicators,
            riichiDiscards: riichiDiscards
        )

        // Assert
        XCTAssertEqual(context.discards.count, 4)
        XCTAssertEqual(context.discards[0].count, 2)
        XCTAssertEqual(context.discards[1].count, 1)
        XCTAssertEqual(context.discards[2].count, 0)
        XCTAssertEqual(context.discards[3].count, 3)
        XCTAssertEqual(context.discards[0][0], Tile(suit: .m, rank: 1))
        XCTAssertEqual(context.discards[3][2], Tile(suit: .s, rank: 7))

        XCTAssertEqual(context.doraIndicators.count, 2)
        XCTAssertEqual(context.doraIndicators[0], Tile(suit: .m, rank: 5))
        XCTAssertEqual(context.doraIndicators[1], Tile(honor: .wind(.east)))

        XCTAssertEqual(context.riichiDiscards.count, 0)
    }

    func testCodableRoundTrip() throws {
        // Arrange
        let discards = [
            [Tile(suit: .m, rank: 1), Tile(suit: .p, rank: 2)],
            [Tile(suit: .s, rank: 3)],
            [],
            [Tile(honor: .red)]
        ]
        let doraIndicators = [Tile(suit: .m, rank: 5)]
        let riichiDiscards = [Tile(suit: .p, rank: 7)]

        let context = RoundContext(
            discards: discards,
            doraIndicators: doraIndicators,
            riichiDiscards: riichiDiscards
        )

        // Act: Encode and decode
        let encoder = JSONEncoder()
        let data = try encoder.encode(context)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RoundContext.self, from: data)

        // Assert: Compare all properties
        XCTAssertEqual(decoded.discards.count, context.discards.count)
        for i in 0..<context.discards.count {
            XCTAssertEqual(decoded.discards[i], context.discards[i])
        }
        XCTAssertEqual(decoded.doraIndicators, context.doraIndicators)
        XCTAssertEqual(decoded.riichiDiscards, context.riichiDiscards)
    }
}
