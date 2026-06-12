import Foundation
import CoreGraphics
import Vision
import AppKit
import MahjongCore

/// Hybrid OCR engine combining template matching (fast) + Vision OCR (accurate).
///
/// Strategy per tile:
/// 1. Template matcher returns Top-3 candidate tiles (with scores)
/// 2. Vision OCR returns Top-3 text candidates (with confidence)
/// 3. Fusion: if Vision OCR agrees with template Top-1, boost confidence
///    Otherwise, fall back to template Top-1 with lower confidence
/// 4. Mark as `needsEdit` if confidence < 0.5
public struct HybridOCREngine: OCREngine {
    private let templateMatcher: TemplateMatcher
    private let visionEngine: VisionOCREngine
    private let templateWeight: Double  // 0.6
    private let visionWeight: Double    // 0.4
    private let lowConfidenceThreshold: Double  // 0.5

    public init(
        templateMatcher: TemplateMatcher,
        visionEngine: VisionOCREngine = VisionOCREngine(),
        templateWeight: Double = 0.6,
        visionWeight: Double = 0.4,
        lowConfidenceThreshold: Double = 0.5
    ) {
        self.templateMatcher = templateMatcher
        self.visionEngine = visionEngine
        self.templateWeight = templateWeight
        self.visionWeight = visionWeight
        self.lowConfidenceThreshold = lowConfidenceThreshold
    }

    public func recognize(
        screenshot: CGImage,
        windowBounds: CGRect,
        layout: LayoutTemplate
    ) async throws -> OCRResult {
        // 1. Crop hand region
        let handRegion = cropHand(screenshot: screenshot, windowBounds: windowBounds, layout: layout)

        // 2. Run both passes in parallel
        async let templateResult = runTemplatePass(handRegion: handRegion)
        async let visionResult = await runVisionPass(handRegion: handRegion)

        let (templateSlots, visionSlots) = await (templateResult, visionResult)

        // 3. Fuse results per slot
        let fused = fuseSlots(templateSlots: templateSlots, visionSlots: visionSlots)

        // 4. Build OCRResult
        let handTiles = fused.compactMap { $0.confirmedTile }
        let handCandidates = fused.map { $0.candidates }
        let avgConfidence = fused.isEmpty ? 0.0 :
            fused.map { $0.confidence }.reduce(0, +) / Double(fused.count)

        let confidence = ConfidenceMap(
            hand: avgConfidence,
            discard: 0.0,  // TODO
            dora: 0.0
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

    // MARK: - Template pass

    private func runTemplatePass(handRegion: CGImage?) async -> [[TileMatch]] {
        guard let region = handRegion else { return [] }
        // For v1, we treat the whole hand as a single tile (no segmentation yet)
        // Task 9.4 will add proper tile segmentation
        let matches = templateMatcher.match(tileImage: region, topN: 3)
        return [matches]
    }

    // MARK: - Vision pass

    private func runVisionPass(handRegion: CGImage?) async -> [HandTileCandidate] {
        guard let region = handRegion else { return [] }
        // Use Vision OCR pass A (raw image)
        return await runRawVisionPass(image: region)
    }

    private func runRawVisionPass(image: CGImage) async -> [HandTileCandidate] {
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                let candidates = observations.compactMap { obs -> HandTileCandidate? in
                    guard let top = obs.topCandidates(1).first else { return nil }
                    return VisionOCREngine.parseTileText(top.string, confidence: Double(top.confidence))
                }
                continuation.resume(returning: candidates)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            try? handler.perform([request])
        }
    }

    // MARK: - Fusion

    /// Fuses template matching and Vision OCR results per slot.
    func fuseSlots(
        templateSlots: [[TileMatch]],
        visionSlots: [HandTileCandidate]
    ) -> [FusedSlot] {
        // For v1, we assume hand has up to 14 slots
        let slotCount = 14
        var results: [FusedSlot] = []

        for i in 0..<slotCount {
            // Template Top-1
            let templateTop = i < templateSlots.count ? templateSlots[i].first : nil

            // Vision Top-1
            let visionTop = i < visionSlots.count ? visionSlots[i] : nil

            // Compute fused confidence
            let (tile, confidence) = fuse(
                templateMatch: templateTop,
                visionCandidate: visionTop
            )

            // Build candidate list (Top-3 from template + Vision agreement)
            var candidates: [HandTileCandidate] = []
            if let t = templateTop {
                candidates.append(HandTileCandidate(tile: t.tile, confidence: t.score))
            }
            if let v = visionTop, !candidates.contains(where: { $0.tile == v.tile }) {
                candidates.append(v)
            }

            let needsEdit = confidence < lowConfidenceThreshold
            results.append(FusedSlot(
                index: i,
                confirmedTile: tile,
                confidence: confidence,
                candidates: candidates,
                needsEdit: needsEdit
            ))
        }

        return results
    }

    /// Fuses a single slot's template and Vision results.
    func fuse(
        templateMatch: TileMatch?,
        visionCandidate: HandTileCandidate?
    ) -> (Tile?, Double) {
        // Case 1: Both agree
        if let t = templateMatch, let v = visionCandidate, t.tile == v.tile {
            let confidence = templateWeight * t.score + visionWeight * v.confidence
            return (t.tile, min(confidence, 1.0))
        }

        // Case 2: Only template
        if let t = templateMatch, visionCandidate == nil {
            return (t.tile, t.score * templateWeight)
        }

        // Case 3: Only Vision
        if let t = templateMatch, let v = visionCandidate, t.tile != v.tile {
            // Disagreement: prefer template (faster, more accurate for fixed UI)
            return (t.tile, t.score * templateWeight)
        }

        return (nil, 0.0)
    }

    // MARK: - Helpers

    private func cropHand(
        screenshot: CGImage,
        windowBounds: CGRect,
        layout: LayoutTemplate
    ) -> CGImage? {
        let pixelRect = CGRect(
            x: windowBounds.origin.x + layout.handRect.origin.x * windowBounds.width,
            y: windowBounds.origin.y + layout.handRect.origin.y * windowBounds.height,
            width: layout.handRect.width * windowBounds.width,
            height: layout.handRect.height * windowBounds.height
        )
        return screenshot.cropping(to: pixelRect)
    }
}

/// A single fused tile slot (per-position in hand).
public struct FusedSlot: Sendable, Hashable {
    public let index: Int
    public let confirmedTile: Tile?
    public let confidence: Double  // 0.0 - 1.0
    public let candidates: [HandTileCandidate]
    public let needsEdit: Bool      // True if confidence < threshold

    public init(
        index: Int,
        confirmedTile: Tile?,
        confidence: Double,
        candidates: [HandTileCandidate],
        needsEdit: Bool
    ) {
        self.index = index
        self.confirmedTile = confirmedTile
        self.confidence = confidence
        self.candidates = candidates
        self.needsEdit = needsEdit
    }
}
