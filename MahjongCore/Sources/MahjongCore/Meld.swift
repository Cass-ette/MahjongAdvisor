import Foundation

public struct Meld: Sendable, Codable, Hashable {
    public enum Kind: Sendable, Codable, Hashable {
        case pon
        case chi
        case kan(closed: Bool)
    }

    public let kind: Kind
    public let tiles: [Tile]   // 4 for kan, 3 otherwise
    public let fromPlayer: Int?  // 暗杠: nil

    public init(kind: Kind, tiles: [Tile], fromPlayer: Int?) {
        self.kind = kind
        self.tiles = tiles
        self.fromPlayer = fromPlayer
    }
}
