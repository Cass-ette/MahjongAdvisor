import XCTest
@testable import MahjongCore

final class TileTests: XCTestCase {
    func testNumberTileInit() {
        let tile = Tile(suit: .m, rank: 5)
        XCTAssertEqual(tile.suit, .m)
        XCTAssertEqual(tile.rank, 5)
        XCTAssertNil(tile.honor)
        XCTAssertFalse(tile.isRed)
    }

    func testIsRedOnlyValidFor5m5p5s() {
        // Valid red tiles
        let red5m = Tile(suit: .m, rank: 5, isRed: true)
        XCTAssertTrue(red5m.isRed)

        let red5p = Tile(suit: .p, rank: 5, isRed: true)
        XCTAssertTrue(red5p.isRed)

        let red5s = Tile(suit: .s, rank: 5, isRed: true)
        XCTAssertTrue(red5s.isRed)

        // Test static helper
        XCTAssertTrue(Tile.isRedValid(suit: .m, rank: 5))
        XCTAssertTrue(Tile.isRedValid(suit: .p, rank: 5))
        XCTAssertTrue(Tile.isRedValid(suit: .s, rank: 5))
        XCTAssertFalse(Tile.isRedValid(suit: .m, rank: 4))
        XCTAssertFalse(Tile.isRedValid(suit: .z, rank: 0))
    }

    func testHonorTileInit() {
        let eastWind = Tile(honor: .wind(.east))
        XCTAssertEqual(eastWind.suit, .z)
        XCTAssertEqual(eastWind.rank, 0)
        XCTAssertEqual(eastWind.honor, .wind(.east))
        XCTAssertFalse(eastWind.isRed)
    }

    func testDragonTileInit() {
        let redDragon = Tile(honor: .red)
        XCTAssertEqual(redDragon.suit, .z)
        XCTAssertEqual(redDragon.rank, 0)
        XCTAssertEqual(redDragon.honor, .red)
        XCTAssertFalse(redDragon.isRed)
    }

    func testEquality() {
        let tile1 = Tile(suit: .m, rank: 5, isRed: false)
        let tile2 = Tile(suit: .m, rank: 5, isRed: false)
        let tile3 = Tile(suit: .m, rank: 5, isRed: true)
        let tile4 = Tile(suit: .p, rank: 5)

        XCTAssertEqual(tile1, tile2)
        XCTAssertNotEqual(tile1, tile3)
        XCTAssertNotEqual(tile1, tile4)
    }

    func testCodableRoundTrip() throws {
        let tile = Tile(suit: .m, rank: 5, isRed: true)
        let encoder = JSONEncoder()
        let data = try encoder.encode(tile)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Tile.self, from: data)
        XCTAssertEqual(tile, decoded)
    }
}
