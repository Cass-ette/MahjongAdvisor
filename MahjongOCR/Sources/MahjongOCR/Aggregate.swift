import Foundation
import MahjongCore

/// Aggregates multiple OCR candidate recognitions for a single hand slot.
public enum Aggregate {
    public struct SlotResult: Sendable {
        public let confirmed: HandTileCandidate?
        public let candidates: [HandTileCandidate]  // top 3, sorted by confidence desc

        public init(confirmed: HandTileCandidate?, candidates: [HandTileCandidate]) {
            self.confirmed = confirmed
            self.candidates = candidates
        }
    }

    /// Aggregates 3 candidate recognitions for a single hand slot.
    /// - If 2+ passes agree on the same tile (each with confidence ≥ threshold) → confirm, avg confidence
    /// - Else → all 3 candidates are surfaced (sorted by confidence desc)
    public static func aggregateSlot(
        passes: [[HandTileCandidate]],
        threshold: Double = 0.6
    ) -> SlotResult {
        // Flatten and filter by threshold
        let allCandidates = passes.flatMap { $0 }.filter { $0.confidence >= threshold }

        // Group by tile
        var byTile: [Tile: [HandTileCandidate]] = [:]
        for candidate in allCandidates {
            byTile[candidate.tile, default: []].append(candidate)
        }

        // Find majority (2+ agree)
        for (tile, candidates) in byTile where candidates.count >= 2 {
            let avgConfidence = candidates.map { $0.confidence }.reduce(0, +) / Double(candidates.count)
            return SlotResult(
                confirmed: HandTileCandidate(tile: tile, confidence: avgConfidence),
                candidates: [HandTileCandidate(tile: tile, confidence: avgConfidence)]
            )
        }

        // No majority: return top 3 by confidence
        let top3 = allCandidates
            .sorted { $0.confidence > $1.confidence }
            .prefix(3)
        return SlotResult(confirmed: nil, candidates: Array(top3))
    }

    /// Aggregates all hand slots from a 14-slot hand.
    /// - Parameters:
    ///   - slots: Array of 3-pass candidate lists, one per hand slot (14 slots total)
    ///   - threshold: Minimum confidence for a candidate to count toward majority
    /// - Returns: Array of slot results
    public static func aggregateHand(
        slots: [[[HandTileCandidate]]],
        threshold: Double = 0.6
    ) -> [SlotResult] {
        return slots.map { aggregateSlot(passes: $0, threshold: threshold) }
    }
}
