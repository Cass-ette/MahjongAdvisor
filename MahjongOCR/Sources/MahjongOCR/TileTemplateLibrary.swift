import Foundation
import CoreGraphics
import AppKit
import MahjongCore

/// Loads 34 tile templates (1-9m/p/s + 7 honors) from the bundle.
/// Falls back to an empty library if templates are not bundled (v1).
public final class TileTemplateLibrary: @unchecked Sendable {
    public let templates: [TileTemplate]
    public let isEmpty: Bool

    public init(bundle: Bundle = .main) {
        // For v1, no templates are bundled. We construct a placeholder list
        // of TileTemplate entries with no actual image data.
        // Task 9.3 will add real PNG templates via a build script.
        var templates: [TileTemplate] = []

        // 1-9m, 1-9p, 1-9s
        for suit in [Suit.m, .p, .s] {
            for rank in 1...9 {
                let tile = Tile(suit: suit, rank: rank)
                let name = TileTemplate.fileName(for: tile)
                templates.append(TileTemplate(
                    tile: tile,
                    imageName: "\(name).png",
                    size: CGSize(width: 32, height: 44)  // standard tile aspect
                ))
            }
        }

        // Honor tiles
        for honor: Honor in [.wind(.east), .wind(.south), .wind(.west), .wind(.north),
                              .white, .green, .red] {
            let tile = Tile(honor: honor)
            let name = TileTemplate.fileName(for: tile)
            templates.append(TileTemplate(
                tile: tile,
                imageName: "\(name).png",
                size: CGSize(width: 32, height: 44)
            ))
        }

        self.templates = templates
        self.isEmpty = templates.isEmpty
    }

    /// Total number of templates (should be 34 when fully populated).
    public var count: Int { templates.count }

    /// Returns all templates (for matching).
    public func allTemplates() -> [TileTemplate] {
        templates
    }

    /// Loads template image data from bundle (if available).
    public func loadImageData(for template: TileTemplate) -> Data? {
        // v1 stub: returns nil (no templates bundled yet)
        // Task 9.3 will populate the bundle via a build script
        return nil
    }
}
