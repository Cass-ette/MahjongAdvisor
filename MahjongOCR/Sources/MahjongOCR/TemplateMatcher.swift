import Foundation
import CoreGraphics
import AppKit
import MahjongCore

/// Matches a tile image against the template library.
/// Uses normalized cross-correlation (NCC) for template matching.
public class TemplateMatcher: @unchecked Sendable {
    public let library: TileTemplateLibrary

    public init(library: TileTemplateLibrary) {
        self.library = library
    }

    /// Matches a tile-sized image against all templates.
    /// Returns sorted matches (highest score first), capped at topN.
    open func match(tileImage: CGImage, topN: Int = 3) -> [TileMatch] {
        // v1 stub: returns uniform low scores (no real matching yet)
        // Real implementation will use vImage / Accelerate framework
        // for normalized cross-correlation (NCC) template matching.
        //
        // When templates are bundled (Task 9.3), this will:
        // 1. Convert tileImage to grayscale
        // 2. For each template:
        //    a. Load template image
        //    b. Resize to tile size
        //    c. Compute NCC
        //    d. Return score 0.0 - 1.0
        // 3. Sort by score, return top N

        return library.allTemplates().enumerated().map { index, template in
            // Placeholder: return identical low score for all
            // Real matching will compute actual NCC values
            let placeholderScore = 1.0 - Double(index) * 0.001
            let location = CGRect(x: 0, y: 0, width: tileImage.width, height: tileImage.height)
            return TileMatch(tile: template.tile, score: placeholderScore, location: location)
        }.prefix(topN).map { $0 }
    }
}
