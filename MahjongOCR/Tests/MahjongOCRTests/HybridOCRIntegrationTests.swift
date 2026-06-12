import XCTest
import CoreGraphics
import AppKit
@testable import MahjongOCR
import MahjongCore

/// End-to-end integration tests for HybridOCREngine.
/// Uses synthetic images + mock matcher to verify pipeline plumbing.
final class HybridOCRIntegrationTests: XCTestCase {

    // MARK: - Helper: create synthetic screenshot

    /// Creates a 1920x1080 solid-color screenshot (no real tiles).
    private func makeSyntheticScreenshot() -> CGImage {
        let size = CGSize(width: 1920, height: 1080)
        let img = NSImage(size: size)
        img.lockFocus()
        NSColor.darkGray.setFill()
        NSRect(origin: .zero, size: size).fill()
        img.unlockFocus()
        return img.cgImage(forProposedRect: nil, context: nil, hints: nil)!
    }

    // MARK: - Full pipeline test

    func testFullPipelineReturns14Slots() async throws {
        let library = TileTemplateLibrary()
        let matcher = TemplateMatcher(library: library)
        let engine = HybridOCREngine(templateMatcher: matcher)

        let screenshot = makeSyntheticScreenshot()
        let windowBounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let layout = LayoutTemplate.default

        let result = try await engine.recognize(
            screenshot: screenshot,
            windowBounds: windowBounds,
            layout: layout
        )

        // v1 engine always emits 14 slots (no segmentation yet)
        XCTAssertEqual(result.handTileCandidates.count, 14, "Should have exactly 14 hand slots")

        // In v1, only slot 0 has a template match (the whole hand is treated as one tile).
        // Slot 0 should have at least 1 candidate from the template matcher.
        XCTAssertFalse(result.handTileCandidates[0].isEmpty, "Slot 0 should have template candidates")
    }

    func testEmptyScreenshotProducesLowConfidence() async throws {
        let library = TileTemplateLibrary()
        let matcher = TemplateMatcher(library: library)
        let engine = HybridOCREngine(templateMatcher: matcher)

        let screenshot = makeSyntheticScreenshot()
        let result = try await engine.recognize(
            screenshot: screenshot,
            windowBounds: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            layout: .default
        )

        // Synthetic image should produce very low confidence
        XCTAssertLessThan(result.confidence.hand, 0.5,
            "Empty screenshot should have low confidence (< 0.5)")
    }

    func testRecognizeCompletesWithinTimeout() async throws {
        let library = TileTemplateLibrary()
        let matcher = TemplateMatcher(library: library)
        let engine = HybridOCREngine(templateMatcher: matcher)

        let screenshot = makeSyntheticScreenshot()
        let layout = LayoutTemplate.default
        let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)

        // 3-second timeout (generous for stub; real engine may need more)
        let result = try await withThrowingTaskGroup(of: OCRResult.self) { group in
            group.addTask {
                try await engine.recognize(
                    screenshot: screenshot,
                    windowBounds: bounds,
                    layout: layout
                )
            }
            group.addTask {
                try await Task.sleep(nanoseconds: 3_000_000_000)
                throw TimeoutError()
            }
            // Return first completed
            for try await first in group {
                group.cancelAll()
                return first
            }
            throw TimeoutError()
        }

        XCTAssertNotNil(result, "Should complete within 3 seconds")
    }

    // MARK: - Confidence threshold tests

    func testNeedsEditFlagTriggersOnLowConfidence() async throws {
        let library = TileTemplateLibrary()
        // Use a matcher that returns low scores
        let matcher = LowScoreMatcher(library: library)
        let engine = HybridOCREngine(templateMatcher: matcher, lowConfidenceThreshold: 0.5)

        let result = try await engine.recognize(
            screenshot: makeSyntheticScreenshot(),
            windowBounds: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            layout: .default
        )

        // Low scores → low confidence for slot 0
        // v1: confidence is averaged across 14 slots, so overall is very low
        XCTAssertLessThan(result.confidence.hand, 0.5,
            "Low matcher scores should produce low overall confidence (< 0.5)")
    }

    func testHighConfidenceMatcherProducesHigherScore() async throws {
        let library = TileTemplateLibrary()
        let lowMatcher = LowScoreMatcher(library: library)
        let highMatcher = HighScoreMatcher(library: library)

        let lowEngine = HybridOCREngine(templateMatcher: lowMatcher)
        let highEngine = HybridOCREngine(templateMatcher: highMatcher)

        let screenshot = makeSyntheticScreenshot()
        let bounds = CGRect(x: 0, y: 0, width: 1920, height: 1080)

        let lowResult = try await lowEngine.recognize(
            screenshot: screenshot,
            windowBounds: bounds,
            layout: .default
        )
        let highResult = try await highEngine.recognize(
            screenshot: screenshot,
            windowBounds: bounds,
            layout: .default
        )

        // High matcher scores (0.95) should yield higher overall confidence
        // than low matcher scores (0.1), even after averaging over 14 slots
        XCTAssertGreaterThan(highResult.confidence.hand, lowResult.confidence.hand,
            "High matcher scores should produce higher confidence than low matcher scores")
    }
}

// MARK: - Mock matchers

/// A matcher that always returns the lowest possible scores.
final class LowScoreMatcher: TemplateMatcher {
    override func match(tileImage: CGImage, topN: Int = 3) -> [TileMatch] {
        return super.match(tileImage: tileImage, topN: topN).map { match in
            TileMatch(tile: match.tile, score: 0.1, location: match.location)
        }
    }
}

/// A matcher that always returns the highest possible scores.
final class HighScoreMatcher: TemplateMatcher {
    override func match(tileImage: CGImage, topN: Int = 3) -> [TileMatch] {
        return super.match(tileImage: tileImage, topN: topN).map { match in
            TileMatch(tile: match.tile, score: 0.95, location: match.location)
        }
    }
}

struct TimeoutError: Error {}
