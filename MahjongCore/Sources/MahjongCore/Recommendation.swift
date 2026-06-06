import Foundation

public enum Recommendation: Sendable, Codable {
    case discard(tile: Tile, reason: String, shanten: Int, ukeIra: [UkeIraEntry])
    case riichi(discard: Tile, ukeIra: [UkeIraEntry])
}

public struct UkeIraEntry: Sendable, Codable, Hashable {
    public let tile: Tile
    public let count: Int
    public let waitType: WaitType

    public init(tile: Tile, count: Int, waitType: WaitType) {
        self.tile = tile
        self.count = count
        self.waitType = waitType
    }
}

public enum WaitType: String, Sendable, Codable, Hashable {
    case ryanmen, kanchan, penchan, tanki, toitsu, shanpon
}
