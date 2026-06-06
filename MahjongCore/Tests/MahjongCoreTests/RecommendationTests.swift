import Testing
@testable import MahjongCore

@Suite("Recommendation Tests")
struct RecommendationTests {

    @Test("Discard case with tile, reason, shanten, and ukeIra")
    func testDiscardCase() throws {
        let tile = Tile(suit: .m, rank: 5)
        let ukeIra = [
            UkeIraEntry(tile: Tile(suit: .m, rank: 3), count: 4, waitType: .ryanmen),
            UkeIraEntry(tile: Tile(suit: .m, rank: 6), count: 4, waitType: .ryanmen)
        ]

        let recommendation = Recommendation.discard(
            tile: tile,
            reason: "Maximize wait tiles",
            shanten: 1,
            ukeIra: ukeIra
        )

        // Validate via pattern matching
        if case .discard(let discardTile, let reason, let shanten, let ukeIraEntries) = recommendation {
            #expect(discardTile == tile)
            #expect(reason == "Maximize wait tiles")
            #expect(shanten == 1)
            #expect(ukeIraEntries.count == 2)
            #expect(ukeIraEntries[0].tile == Tile(suit: .m, rank: 3))
            #expect(ukeIraEntries[0].count == 4)
            #expect(ukeIraEntries[0].waitType == .ryanmen)
        } else {
            Issue.record("Expected discard case")
        }
    }

    @Test("Riichi case with discard and ukeIra")
    func testRiichiCase() throws {
        let tile = Tile(suit: .p, rank: 7)
        let ukeIra = [
            UkeIraEntry(tile: Tile(suit: .p, rank: 5), count: 3, waitType: .kanchan),
            UkeIraEntry(tile: Tile(suit: .p, rank: 8), count: 4, waitType: .ryanmen)
        ]

        let recommendation = Recommendation.riichi(
            discard: tile,
            ukeIra: ukeIra
        )

        if case .riichi(let discardTile, let ukeIraEntries) = recommendation {
            #expect(discardTile == tile)
            #expect(ukeIraEntries.count == 2)
            #expect(ukeIraEntries[1].tile == Tile(suit: .p, rank: 8))
            #expect(ukeIraEntries[1].waitType == .ryanmen)
        } else {
            Issue.record("Expected riichi case")
        }
    }

    @Test("WaitType enum has all expected raw values")
    func testWaitTypeValues() throws {
        #expect(WaitType.ryanmen.rawValue == "ryanmen")
        #expect(WaitType.kanchan.rawValue == "kanchan")
        #expect(WaitType.penchan.rawValue == "penchan")
        #expect(WaitType.tanki.rawValue == "tanki")
        #expect(WaitType.toitsu.rawValue == "toitsu")
        #expect(WaitType.shanpon.rawValue == "shanpon")
    }

    @Test("MahjongError cases can be constructed")
    func testErrorCases() throws {
        let errors: [MahjongError] = [
            .handSizeInvalid(15),
            .tileCountOverflow(Tile(suit: .m, rank: 1), count: 5),
            .unsupportedRule("Three-player mahjong"),
            .parseFailure("Invalid tile notation: 0m"),
            .ocrLowConfidence(region: "dora", score: 0.45)
        ]

        // Validate each can be constructed and matched
        #expect(errors.count == 5)

        if case .handSizeInvalid(let size) = errors[0] {
            #expect(size == 15)
        } else {
            Issue.record("Expected handSizeInvalid")
        }

        if case .tileCountOverflow(let tile, let count) = errors[1] {
            #expect(tile == Tile(suit: .m, rank: 1))
            #expect(count == 5)
        } else {
            Issue.record("Expected tileCountOverflow")
        }

        if case .unsupportedRule(let rule) = errors[2] {
            #expect(rule == "Three-player mahjong")
        } else {
            Issue.record("Expected unsupportedRule")
        }

        if case .parseFailure(let msg) = errors[3] {
            #expect(msg == "Invalid tile notation: 0m")
        } else {
            Issue.record("Expected parseFailure")
        }

        if case .ocrLowConfidence(let region, let score) = errors[4] {
            #expect(region == "dora")
            #expect(score == 0.45)
        } else {
            Issue.record("Expected ocrLowConfidence")
        }
    }
}
