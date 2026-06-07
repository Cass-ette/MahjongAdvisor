import XCTest
@testable import MahjongCore

final class UkeIraTests: XCTestCase {
    func testCountInWall_NonRedTile_EmptyHand() {
        let count = UkeIra.countInWall(
            tile: Tile(suit: .m, rank: 1),
            visible: [],
            redFivesRemaining: [:]
        )
        XCTAssertEqual(count, 4)
    }

    func testCountInWall_OneVisible() {
        let count = UkeIra.countInWall(
            tile: Tile(suit: .m, rank: 1),
            visible: [Tile(suit: .m, rank: 1)],
            redFivesRemaining: [:]
        )
        XCTAssertEqual(count, 3)
    }

    func testCountInWall_AllVisible() {
        let count = UkeIra.countInWall(
            tile: Tile(suit: .m, rank: 1),
            visible: Array(repeating: Tile(suit: .m, rank: 1), count: 4),
            redFivesRemaining: [:]
        )
        XCTAssertEqual(count, 0)
    }

    func testCountInWall_NonRed5_FreshWall() {
        let count = UkeIra.countInWall(
            tile: Tile(suit: .m, rank: 5),
            visible: [],
            redFivesRemaining: [.m: 1]
        )
        XCTAssertEqual(count, 3)
    }

    func testCountInWall_NonRed5_RedUsed() {
        let count = UkeIra.countInWall(
            tile: Tile(suit: .m, rank: 5),
            visible: [Tile(suit: .m, rank: 5, isRed: true)],
            redFivesRemaining: [.m: 0]
        )
        XCTAssertEqual(count, 3)
    }

    func testCountInWall_NonRed5_RedAndNonRedVisible() {
        // 1 red 5m + 1 non-red 5m visible, redRemaining = 0
        // Total 5m in wall: 4 (1 red + 3 non-red)
        // Red 5m has been seen (redRemaining=0)
        // Non-red 5m visible: 1
        // Available non-red 5m in wall: 3 - 1 = 2
        let count = UkeIra.countInWall(
            tile: Tile(suit: .m, rank: 5),
            visible: [Tile(suit: .m, rank: 5, isRed: true), Tile(suit: .m, rank: 5)],
            redFivesRemaining: [.m: 0]
        )
        XCTAssertEqual(count, 2)
    }

    func testCountInWall_NonRed5_OneNonRed5Visible() {
        let count = UkeIra.countInWall(
            tile: Tile(suit: .m, rank: 5),
            visible: [Tile(suit: .m, rank: 5)],
            redFivesRemaining: [.m: 1]
        )
        XCTAssertEqual(count, 2)
    }

    func testCountInWall_Red5_Available() {
        let count = UkeIra.countInWall(
            tile: Tile(suit: .m, rank: 5, isRed: true),
            visible: [],
            redFivesRemaining: [.m: 1]
        )
        XCTAssertEqual(count, 1)
    }

    func testCountInWall_Red5_Used() {
        let count = UkeIra.countInWall(
            tile: Tile(suit: .m, rank: 5, isRed: true),
            visible: [Tile(suit: .m, rank: 5, isRed: true)],
            redFivesRemaining: [.m: 0]
        )
        XCTAssertEqual(count, 0)
    }

    func testCountInWall_HonorTile() {
        let count = UkeIra.countInWall(
            tile: Tile(honor: .wind(.east)),
            visible: [],
            redFivesRemaining: [:]
        )
        XCTAssertEqual(count, 4)
    }
}
