import Foundation

public enum Honor: Sendable, Codable, Hashable {
    case wind(Wind)
    case white   // 白
    case green   // 發
    case red     // 中
}
