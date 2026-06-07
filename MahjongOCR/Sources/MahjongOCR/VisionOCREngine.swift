import Foundation
import CoreGraphics
import Vision
import AppKit
import MahjongCore

/// OCR engine using Apple Vision framework with 3-pass aggregation.
/// Pass A: raw image + VNRecognizeTextRequest
/// Pass B: binarized image + VNRecognizeTextRequest
/// Pass C: template matching (stub for v1)
public struct VisionOCREngine: OCREngine {
    public init() {}

    public func recognize(
        screenshot: CGImage,
        windowBounds: CGRect,
        layout: LayoutTemplate
    ) async throws -> OCRResult {
        // 1. Crop the screenshot to the hand region
        let handRegion = crop(
            screenshot: screenshot,
            windowBounds: windowBounds,
            normalizedRect: layout.handRect
        )

        // 2. Run 3 passes
        let passA = await runRawPass(image: handRegion)
        let passB = await runBinarizedPass(image: handRegion)
        let passC = await runTemplatePass(image: handRegion)

        // 3. Aggregate per slot
        let aggregated = aggregateSlots(passes: [passA, passB, passC])

        // 4. Build OCRResult
        let handTiles = aggregated.compactMap { $0.confirmed?.tile }
        let handCandidates = aggregated.map { $0.candidates }
        let handConfidence = aggregated.isEmpty
            ? 0.0
            : aggregated.map { $0.confirmed?.confidence ?? 0 }.reduce(0, +) / Double(aggregated.count)

        let confidence = ConfidenceMap(
            hand: handConfidence,
            discard: 0.0,  // TODO: parse 牌河
            dora: 0.0      // TODO: parse dora
        )

        return OCRResult(
            handTiles: handTiles.isEmpty ? nil : handTiles,
            melds: nil,
            discards: nil,
            doraIndicators: nil,
            redFivesRemaining: [.m: 1, .p: 1, .s: 1],
            confidence: confidence,
            handTileCandidates: handCandidates
        )
    }

    // MARK: - Region cropping

    /// Crops a screenshot to a normalized sub-rectangle.
    private func crop(
        screenshot: CGImage,
        windowBounds: CGRect,
        normalizedRect: CGRect
    ) -> CGImage? {
        let pixelRect = CGRect(
            x: windowBounds.origin.x + normalizedRect.origin.x * windowBounds.width,
            y: windowBounds.origin.y + normalizedRect.origin.y * windowBounds.height,
            width: normalizedRect.width * windowBounds.width,
            height: normalizedRect.height * windowBounds.height
        )
        return screenshot.cropping(to: pixelRect)
    }

    // MARK: - Pass A: raw

    /// Runs Vision text recognition on the raw (unmodified) image.
    private func runRawPass(image: CGImage?) async -> [HandTileCandidate] {
        guard let image = image else { return [] }
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                let candidates = observations.compactMap { obs -> HandTileCandidate? in
                    guard let top = obs.topCandidates(1).first else { return nil }
                    return Self.parseTileText(top.string, confidence: Double(top.confidence))
                }
                continuation.resume(returning: candidates)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }

    // MARK: - Pass B: binarized

    /// Runs Vision text recognition on a binarized version of the image.
    private func runBinarizedPass(image: CGImage?) async -> [HandTileCandidate] {
        guard let image = image,
              let binarized = Self.binarize(image: image) else { return [] }
        return await runRawPass(image: binarized)
    }

    /// Applies Otsu binarization to an image.
    static func binarize(image: CGImage) -> CGImage? {
        // Stub: returns the original image. Real Otsu implementation in future.
        // TODO: Implement Otsu thresholding for improved contrast
        return image
    }

    // MARK: - Pass C: template matching

    /// Runs template matching pass (stub for v1).
    private func runTemplatePass(image: CGImage?) async -> [HandTileCandidate] {
        // Stub: split image into tile-sized segments and match against templates.
        // Real implementation requires a tile image database.
        return []
    }

    // MARK: - Parsing

    /// Maps OCR text to a Tile.
    /// Supports formats like "1m", "2p", "3s", "東", "南", "白", "發", "中"
    static func parseTileText(_ text: String, confidence: Double) -> HandTileCandidate? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)

        // Honor tiles (Chinese characters)
        let honorMap: [String: Honor] = [
            "東": .wind(.east), "南": .wind(.south), "西": .wind(.west), "北": .wind(.north),
            "白": .white, "發": .green, "中": .red
        ]
        if let honor = honorMap[trimmed] {
            return HandTileCandidate(tile: Tile(honor: honor), confidence: confidence)
        }

        // Number tiles: "1m", "2p", "3s", "0m" (red five), "5m" etc.
        guard trimmed.count >= 2 else { return nil }
        let suitChar = trimmed.last!
        let rankStr = String(trimmed.dropLast())

        let suit: Suit?
        let isRed = rankStr.hasPrefix("0")
        let rankValue = isRed ? 5 : Int(rankStr)

        switch suitChar {
        case "m", "M": suit = .m
        case "p", "P": suit = .p
        case "s", "S": suit = .s
        default: suit = nil
        }

        guard let s = suit, let r = rankValue, r >= 1, r <= 9 else { return nil }
        return HandTileCandidate(
            tile: Tile(suit: s, rank: r, isRed: isRed),
            confidence: confidence
        )
    }

    // MARK: - Aggregation helper

    /// Aggregates 3 passes of slot candidates into per-slot results.
    private func aggregateSlots(passes: [[HandTileCandidate]]) -> [Aggregate.SlotResult] {
        // Assume each pass has 14 candidates (one per hand slot)
        let slotCount = passes.map { $0.count }.max() ?? 0
        var results: [Aggregate.SlotResult] = []
        for i in 0..<slotCount {
            let slotPasses = passes.map { $0.indices.contains(i) ? [$0[i]] : [] }
            results.append(Aggregate.aggregateSlot(passes: slotPasses))
        }
        return results
    }
}
