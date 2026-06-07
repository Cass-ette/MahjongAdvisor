import XCTest
@testable import MahjongOCR
import MahjongCore

/// Tests for VisionOCREngine text parsing logic.
/// Full integration tests with real Vision framework calls require screenshots.
final class VisionOCREngineTests: XCTestCase {

    // MARK: - Text parsing

    func testParseTileText_NumberTiles() {
        XCTAssertEqual(
            VisionOCREngine.parseTileText("1m", confidence: 0.9)?.tile,
            Tile(suit: .m, rank: 1)
        )
        XCTAssertEqual(
            VisionOCREngine.parseTileText("5p", confidence: 0.9)?.tile,
            Tile(suit: .p, rank: 5)
        )
        XCTAssertEqual(
            VisionOCREngine.parseTileText("9s", confidence: 0.9)?.tile,
            Tile(suit: .s, rank: 9)
        )
    }

    func testParseTileText_RedFive() {
        // "0m" is the convention for red 5m
        let result = VisionOCREngine.parseTileText("0m", confidence: 0.85)
        XCTAssertEqual(result?.tile, Tile(suit: .m, rank: 5, isRed: true))
    }

    func testParseTileText_HonorTiles() {
        XCTAssertEqual(
            VisionOCREngine.parseTileText("東", confidence: 0.9)?.tile,
            Tile(honor: .wind(.east))
        )
        XCTAssertEqual(
            VisionOCREngine.parseTileText("南", confidence: 0.9)?.tile,
            Tile(honor: .wind(.south))
        )
        XCTAssertEqual(
            VisionOCREngine.parseTileText("西", confidence: 0.9)?.tile,
            Tile(honor: .wind(.west))
        )
        XCTAssertEqual(
            VisionOCREngine.parseTileText("北", confidence: 0.9)?.tile,
            Tile(honor: .wind(.north))
        )
        XCTAssertEqual(
            VisionOCREngine.parseTileText("白", confidence: 0.9)?.tile,
            Tile(honor: .white)
        )
        XCTAssertEqual(
            VisionOCREngine.parseTileText("發", confidence: 0.9)?.tile,
            Tile(honor: .green)
        )
        XCTAssertEqual(
            VisionOCREngine.parseTileText("中", confidence: 0.9)?.tile,
            Tile(honor: .red)
        )
    }

    func testParseTileText_ConfidencePreserved() {
        let result = VisionOCREngine.parseTileText("5p", confidence: 0.75)
        XCTAssertEqual(result?.confidence, 0.75)
    }

    func testParseTileText_InvalidReturnsNil() {
        XCTAssertNil(VisionOCREngine.parseTileText("xyz", confidence: 0.9))
        XCTAssertNil(VisionOCREngine.parseTileText("", confidence: 0.9))
        XCTAssertNil(VisionOCREngine.parseTileText("0z", confidence: 0.9))  // invalid suit
        XCTAssertNil(VisionOCREngine.parseTileText("10m", confidence: 0.9))  // invalid rank
    }

    func testParseTileText_TrimsWhitespace() {
        let result = VisionOCREngine.parseTileText("  5p  ", confidence: 0.9)
        XCTAssertEqual(result?.tile, Tile(suit: .p, rank: 5))
    }

    // MARK: - Engine instantiation

    func testEngineInit() {
        let engine = VisionOCREngine()
        // Just verify it can be created
        _ = engine
    }
}
