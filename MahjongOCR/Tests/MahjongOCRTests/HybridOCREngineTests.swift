import XCTest
import CoreGraphics
import AppKit
@testable import MahjongOCR
import MahjongCore

final class HybridOCREngineTests: XCTestCase {
    // MARK: - Fusion logic tests (no real OCR needed)

    func testFuseAgreementBoostsConfidence() {
        let library = TileTemplateLibrary()
        let matcher = TemplateMatcher(library: library)
        let engine = HybridOCREngine(templateMatcher: matcher)

        // Both template and Vision agree on "5m"
        let templateMatch = TileMatch(
            tile: Tile(suit: .m, rank: 5),
            score: 0.9,
            location: .zero
        )
        let visionCandidate = HandTileCandidate(
            tile: Tile(suit: .m, rank: 5),
            confidence: 0.85
        )

        let (tile, confidence) = engine.fuseForTesting(
            templateMatch: templateMatch,
            visionCandidate: visionCandidate
        )

        XCTAssertEqual(tile, Tile(suit: .m, rank: 5))
        XCTAssertGreaterThan(confidence, 0.8, "Agreement should boost confidence above 0.8")
    }

    func testFuseDisagreementFallsBackToTemplate() {
        let library = TileTemplateLibrary()
        let matcher = TemplateMatcher(library: library)
        let engine = HybridOCREngine(templateMatcher: matcher)

        // Template says 5m, Vision says 6m
        let templateMatch = TileMatch(
            tile: Tile(suit: .m, rank: 5),
            score: 0.9,
            location: .zero
        )
        let visionCandidate = HandTileCandidate(
            tile: Tile(suit: .m, rank: 6),
            confidence: 0.85
        )

        let (tile, confidence) = engine.fuseForTesting(
            templateMatch: templateMatch,
            visionCandidate: visionCandidate
        )

        XCTAssertEqual(tile, Tile(suit: .m, rank: 5), "Should prefer template on disagreement")
        XCTAssertLessThan(confidence, 0.8, "Disagreement should lower confidence")
    }

    func testFuseOnlyTemplate() {
        let library = TileTemplateLibrary()
        let matcher = TemplateMatcher(library: library)
        let engine = HybridOCREngine(templateMatcher: matcher)

        let templateMatch = TileMatch(
            tile: Tile(suit: .p, rank: 3),
            score: 0.7,
            location: .zero
        )

        let (tile, confidence) = engine.fuseForTesting(
            templateMatch: templateMatch,
            visionCandidate: nil
        )

        XCTAssertEqual(tile, Tile(suit: .p, rank: 3))
        XCTAssertEqual(confidence, 0.42, accuracy: 0.01, "Template-only = 0.7 * 0.6 = 0.42")
    }

    func testFuseBothNil() {
        let library = TileTemplateLibrary()
        let matcher = TemplateMatcher(library: library)
        let engine = HybridOCREngine(templateMatcher: matcher)

        let (tile, confidence) = engine.fuseForTesting(
            templateMatch: nil,
            visionCandidate: nil
        )

        XCTAssertNil(tile)
        XCTAssertEqual(confidence, 0.0)
    }

    // MARK: - FusedSlot tests

    func testFusedSlotNeedsEditFlag() {
        let library = TileTemplateLibrary()
        let matcher = TemplateMatcher(library: library)
        let engine = HybridOCREngine(templateMatcher: matcher, lowConfidenceThreshold: 0.5)

        // Low confidence scenario
        let slots = engine.fuseSlotsForTesting(
            templateSlots: [[TileMatch(tile: Tile(suit: .m, rank: 1), score: 0.3, location: .zero)]],
            visionSlots: []
        )

        XCTAssertFalse(slots.isEmpty)
        XCTAssertTrue(slots[0].needsEdit, "Low confidence should set needsEdit")
        XCTAssertLessThan(slots[0].confidence, 0.5)
    }

    func testFusedSlotNoEditNeeded() {
        let library = TileTemplateLibrary()
        let matcher = TemplateMatcher(library: library)
        let engine = HybridOCREngine(templateMatcher: matcher, lowConfidenceThreshold: 0.5)

        // High confidence: template 0.9 + Vision agrees 0.9
        let slots = engine.fuseSlotsForTesting(
            templateSlots: [[TileMatch(tile: Tile(suit: .m, rank: 5), score: 0.9, location: .zero)]],
            visionSlots: [HandTileCandidate(tile: Tile(suit: .m, rank: 5), confidence: 0.9)]
        )

        XCTAssertFalse(slots.isEmpty)
        XCTAssertFalse(slots[0].needsEdit, "High confidence should not set needsEdit")
        XCTAssertGreaterThan(slots[0].confidence, 0.7)
    }
}

extension HybridOCREngine {
    /// Exposed for testing only.
    func fuseForTesting(
        templateMatch: TileMatch?,
        visionCandidate: HandTileCandidate?
    ) -> (Tile?, Double) {
        return self.fuse(templateMatch: templateMatch, visionCandidate: visionCandidate)
    }

    /// Exposed for testing only.
    func fuseSlotsForTesting(
        templateSlots: [[TileMatch]],
        visionSlots: [HandTileCandidate]
    ) -> [FusedSlot] {
        return self.fuseSlots(templateSlots: templateSlots, visionSlots: visionSlots)
    }
}
