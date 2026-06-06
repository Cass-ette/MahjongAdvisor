import Foundation

public enum Wind: Int, Sendable, Codable, Hashable, CaseIterable {
    case east = 1, south, west, north
}
