import Testing
import Foundation
@testable import MahjongCore

struct MeldTests {

    // pon (ポン): 3 identical tiles
    @Test func testPon() {
        let tile = Tile(suit: .m, rank: 5)
        let meld = Meld(kind: .pon, tiles: [tile, tile, tile], fromPlayer: 1)

        #expect(meld.tiles.count == 3)
        #expect(meld.fromPlayer == 1)
        if case .pon = meld.kind {} else {
            Issue.record("Expected .pon kind")
        }
    }

    // chi (チー): 3 sequential tiles
    @Test func testChi() {
        let t1 = Tile(suit: .p, rank: 3)
        let t2 = Tile(suit: .p, rank: 4)
        let t3 = Tile(suit: .p, rank: 5)
        let meld = Meld(kind: .chi, tiles: [t1, t2, t3], fromPlayer: 2)

        #expect(meld.tiles.count == 3)
        #expect(meld.fromPlayer == 2)
        if case .chi = meld.kind {} else {
            Issue.record("Expected .chi kind")
        }
    }

    // open kan (大明杠)
    @Test func testOpenKan() {
        let tile = Tile(suit: .s, rank: 7)
        let meld = Meld(kind: .kan(closed: false), tiles: [tile, tile, tile, tile], fromPlayer: 0)

        #expect(meld.tiles.count == 4)
        #expect(meld.fromPlayer == 0)
        if case .kan(let closed) = meld.kind {
            #expect(closed == false)
        } else {
            Issue.record("Expected .kan(closed: false)")
        }
    }

    // closed kan (暗杠)
    @Test func testClosedKan() {
        let tile = Tile(honor: .white)
        let meld = Meld(kind: .kan(closed: true), tiles: [tile, tile, tile, tile], fromPlayer: nil)

        #expect(meld.tiles.count == 4)
        #expect(meld.fromPlayer == nil)
        if case .kan(let closed) = meld.kind {
            #expect(closed == true)
        } else {
            Issue.record("Expected .kan(closed: true)")
        }
    }

    // Codable round-trip
    @Test func testCodableRoundTrip() throws {
        let tile = Tile(suit: .m, rank: 1)
        let original = Meld(kind: .pon, tiles: [tile, tile, tile], fromPlayer: 3)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Meld.self, from: data)

        #expect(decoded == original)
    }
}
