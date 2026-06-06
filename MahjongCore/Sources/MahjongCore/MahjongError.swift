import Foundation

public enum MahjongError: Error, Sendable {
    case handSizeInvalid(Int)
    case tileCountOverflow(Tile, count: Int)
    case unsupportedRule(String)
    case parseFailure(String)
    case ocrLowConfidence(region: String, score: Double)
}
