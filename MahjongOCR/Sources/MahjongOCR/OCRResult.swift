import Foundation
import CoreGraphics
import MahjongCore

/// A single candidate for a hand tile position.
public struct HandTileCandidate: Sendable, Hashable {
    public let tile: Tile
    public let confidence: Double

    public init(tile: Tile, confidence: Double) {
        self.tile = tile
        self.confidence = confidence
    }
}

/// Per-region OCR confidence scores.
public struct ConfidenceMap: Sendable {
    public var hand: Double       // 0-1; Edit Mode triggers if < 0.7
    public var discard: Double
    public var dora: Double       // Edit Mode triggers if < 0.7

    public init(hand: Double, discard: Double = 0, dora: Double = 0) {
        self.hand = hand
        self.discard = discard
        self.dora = dora
    }

    /// Overall confidence is the minimum of all regions (any low confidence triggers warnings).
    public var overall: Double {
        min(hand, discard, dora)
    }

    /// Returns true if any region requires user correction.
    public var needsEdit: Bool {
        hand < 0.7 || dora < 0.7
    }
}

/// Result of OCR processing.
public struct OCRResult: Sendable {
    /// Recognized hand tiles (nil = couldn't parse)
    public var handTiles: [Tile]?
    public var melds: [Meld]?
    public var discards: [[Tile]]?            // 4 players
    public var doraIndicators: [Tile]?
    public var redFivesRemaining: [Suit: Int]
    public var confidence: ConfidenceMap
    /// Per-slot top candidates from multi-pass OCR.
    public var handTileCandidates: [[HandTileCandidate]]

    public init(
        handTiles: [Tile]?,
        melds: [Meld]?,
        discards: [[Tile]]?,
        doraIndicators: [Tile]?,
        redFivesRemaining: [Suit: Int],
        confidence: ConfidenceMap,
        handTileCandidates: [[HandTileCandidate]]
    ) {
        self.handTiles = handTiles
        self.melds = melds
        self.discards = discards
        self.doraIndicators = doraIndicators
        self.redFivesRemaining = redFivesRemaining
        self.confidence = confidence
        self.handTileCandidates = handTileCandidates
    }
}
