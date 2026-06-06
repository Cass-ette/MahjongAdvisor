import Foundation

public enum Suit: String, Sendable, Codable, Hashable, CaseIterable {
    case m, p, s, z

    public var isNumberSuit: Bool {
        self != .z
    }
}
