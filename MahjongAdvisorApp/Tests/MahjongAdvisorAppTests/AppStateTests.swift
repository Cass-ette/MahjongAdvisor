import XCTest
@testable import MahjongAdvisorApp
import MahjongCore
import MahjongOCR

@MainActor
final class AppStateTests: XCTestCase {
    func testInitialState() {
        let state = AppState()
        XCTAssertNil(state.ocrResult)
        XCTAssertTrue(state.recommendations.isEmpty)
        XCTAssertEqual(state.mode, .collapsed)
    }

    func testUpdateOCRResult() {
        let state = AppState()
        let result = OCRResult(
            handTiles: [Tile(suit: .m, rank: 1)],
            melds: nil, discards: nil, doraIndicators: nil,
            redFivesRemaining: [:],
            confidence: ConfidenceMap(hand: 0.9, discard: 0.0, dora: 0.0),
            handTileCandidates: []
        )
        state.update(ocrResult: result)
        XCTAssertNotNil(state.ocrResult)
    }

    func testTogglePause() {
        let state = AppState()
        XCTAssertEqual(state.mode, .collapsed)
        state.togglePause()
        XCTAssertEqual(state.mode, .paused)
        state.togglePause()
        XCTAssertEqual(state.mode, .collapsed)
    }

    func testLowHandConfidenceTriggersEditMode() {
        let state = AppState()
        let lowHandConfidence = OCRResult(
            handTiles: [], melds: nil, discards: nil, doraIndicators: nil,
            redFivesRemaining: [:],
            confidence: ConfidenceMap(hand: 0.6, discard: 0.0, dora: 0.9),
            handTileCandidates: []
        )
        state.update(ocrResult: lowHandConfidence)
        XCTAssertEqual(state.mode, .editing)
    }

    func testLowDoraConfidenceTriggersEditMode() {
        let state = AppState()
        let lowDoraConfidence = OCRResult(
            handTiles: [], melds: nil, discards: nil, doraIndicators: nil,
            redFivesRemaining: [:],
            confidence: ConfidenceMap(hand: 0.9, discard: 0.0, dora: 0.6),
            handTileCandidates: []
        )
        state.update(ocrResult: lowDoraConfidence)
        XCTAssertEqual(state.mode, .editing)
    }

    func testHighConfidenceDoesNotTriggerEditMode() {
        let state = AppState()
        let highConfidence = OCRResult(
            handTiles: [], melds: nil, discards: nil, doraIndicators: nil,
            redFivesRemaining: [:],
            confidence: ConfidenceMap(hand: 0.9, discard: 0.0, dora: 0.9),
            handTileCandidates: []
        )
        state.update(ocrResult: highConfidence)
        XCTAssertEqual(state.mode, .collapsed)
    }

    func testAutoTransitionRespectsProtectedModes() {
        let state = AppState()
        state.mode = .paused
        let lowConfidence = OCRResult(
            handTiles: [], melds: nil, discards: nil, doraIndicators: nil,
            redFivesRemaining: [:],
            confidence: ConfidenceMap(hand: 0.6, discard: 0.0, dora: 0.6),
            handTileCandidates: []
        )
        state.update(ocrResult: lowConfidence)
        XCTAssertEqual(state.mode, .paused)
    }
}
