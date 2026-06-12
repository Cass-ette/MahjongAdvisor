import Foundation
import CoreGraphics
import MahjongCore

/// A single tile template for matching.
public struct TileTemplate: Sendable, Hashable {
    public let tile: Tile
    public let imageName: String  // "1m.png", "2p.png", "東.png", etc.
    public let size: CGSize        // Original template image size

    public init(tile: Tile, imageName: String, size: CGSize) {
        self.tile = tile
        self.imageName = imageName
        self.size = size
    }

    /// Conventional filename for a tile (no extension).
    public static func fileName(for tile: Tile) -> String {
        if let honor = tile.honor {
            switch honor {
            case .wind(let w):
                switch w {
                case .east: return "東"
                case .south: return "南"
                case .west: return "西"
                case .north: return "北"
                }
            case .white: return "白"
            case .green: return "發"
            case .red: return "中"
            }
        }
        return "\(tile.rank)\(tile.suit.rawValue)"
    }
}

/// A scored match from template matching.
public struct TileMatch: Sendable, Hashable {
    public let tile: Tile
    public let score: Double       // 0.0 - 1.0 (higher = better match)
    public let location: CGRect    // Where the match was found

    public init(tile: Tile, score: Double, location: CGRect) {
        self.tile = tile
        self.score = score
        self.location = location
    }
}
