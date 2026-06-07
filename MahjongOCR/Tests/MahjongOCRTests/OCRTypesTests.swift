import XCTest
@testable import MahjongOCR
import MahjongCore

final class OCRTypesTests: XCTestCase {

    func testLayoutTemplateCodable() throws {
        let template = LayoutTemplate(
            handRect: CGRect(x: 0.05, y: 0.75, width: 0.6, height: 0.1),
            meldRect: CGRect(x: 0.05, y: 0.6, width: 0.6, height: 0.1),
            discardRects: [
                CGRect(x: 0.05, y: 0.4, width: 0.2, height: 0.1),
                CGRect(x: 0.3, y: 0.4, width: 0.2, height: 0.1),
                CGRect(x: 0.55, y: 0.4, width: 0.2, height: 0.1),
                CGRect(x: 0.8, y: 0.4, width: 0.2, height: 0.1),
            ],
            doraRect: CGRect(x: 0.05, y: 0.05, width: 0.1, height: 0.1)
        )
        let data = try JSONEncoder().encode(template)
        let decoded = try JSONDecoder().decode(LayoutTemplate.self, from: data)
        XCTAssertEqual(decoded.handRect, template.handRect)
        XCTAssertEqual(decoded.discardRects.count, 4)
    }

    func testConfidenceMapOverall() {
        var map = ConfidenceMap(hand: 0.9, discard: 0.5, dora: 0.8)
        XCTAssertEqual(map.overall, 0.5)  // min of all
        map.hand = 0.4
        XCTAssertEqual(map.overall, 0.4)
    }

    func testConfidenceMapNeedsEdit() {
        let highConf = ConfidenceMap(hand: 0.9, discard: 0.5, dora: 0.8)
        XCTAssertFalse(highConf.needsEdit)

        let lowHand = ConfidenceMap(hand: 0.5, discard: 0.9, dora: 0.9)
        XCTAssertTrue(lowHand.needsEdit)

        let lowDora = ConfidenceMap(hand: 0.9, discard: 0.9, dora: 0.5)
        XCTAssertTrue(lowDora.needsEdit)
    }

    func testOCRResultInit() {
        let result = OCRResult(
            handTiles: [Tile(suit: .m, rank: 1), Tile(suit: .m, rank: 2)],
            melds: nil,
            discards: [[], [], [], []],
            doraIndicators: nil,
            redFivesRemaining: [:],
            confidence: ConfidenceMap(hand: 0.9, discard: 0.0, dora: 0.0),
            handTileCandidates: []
        )
        XCTAssertNotNil(result.handTiles)
        XCTAssertEqual(result.handTiles?.count, 2)
        XCTAssertEqual(result.discards?.count, 4)
    }

    func testHandTileCandidate() {
        let candidate = HandTileCandidate(
            tile: Tile(suit: .m, rank: 5),
            confidence: 0.85
        )
        XCTAssertEqual(candidate.tile, Tile(suit: .m, rank: 5))
        XCTAssertEqual(candidate.confidence, 0.85)
    }

    func testLayoutTemplateDefault() {
        let template = LayoutTemplate.default
        XCTAssertEqual(template.discardRects.count, 4)
        // All coordinates should be in 0-1 range (normalized)
        XCTAssertGreaterThanOrEqual(template.handRect.minX, 0)
        XCTAssertLessThanOrEqual(template.handRect.maxX, 1)
    }
}
