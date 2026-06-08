import Foundation
import CoreGraphics

public enum PanelMode: String, Codable, Sendable {
    case collapsed, expanded
}

public struct PanelPosition: Codable, Sendable, Hashable {
    public var x: CGFloat
    public var y: CGFloat

    public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }
}

public struct AppConfig: Sendable {
    public var pollIntervalSeconds: Int
    public var panelPosition: PanelPosition
    public var panelMode: PanelMode
    public var logLevel: String

    public init(
        pollIntervalSeconds: Int = 3,
        panelPosition: PanelPosition = PanelPosition(x: 100, y: 200),
        panelMode: PanelMode = .collapsed,
        logLevel: String = "info"
    ) {
        self.pollIntervalSeconds = pollIntervalSeconds
        self.panelPosition = panelPosition
        self.panelMode = panelMode
        self.logLevel = logLevel
    }
}

extension AppConfig: Codable {
    private enum CodingKeys: String, CodingKey {
        case pollIntervalSeconds
        case panelPosition
        case panelMode
        case logLevel
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pollIntervalSeconds, forKey: .pollIntervalSeconds)
        try container.encode(panelPosition, forKey: .panelPosition)
        try container.encode(panelMode, forKey: .panelMode)
        try container.encode(logLevel, forKey: .logLevel)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pollIntervalSeconds = try container.decodeIfPresent(Int.self, forKey: .pollIntervalSeconds) ?? 3
        panelPosition = try container.decodeIfPresent(PanelPosition.self, forKey: .panelPosition) ?? PanelPosition(x: 100, y: 200)
        panelMode = try container.decodeIfPresent(PanelMode.self, forKey: .panelMode) ?? .collapsed
        logLevel = try container.decodeIfPresent(String.self, forKey: .logLevel) ?? "info"
    }
}

public enum ConfigError: Error {
    case noApplicationSupportDirectory
}

public enum ConfigStore {
    internal static var configURLOverride: URL?

    public static func configFromData(_ data: Data) throws -> AppConfig {
        let decoder = JSONDecoder()
        return try decoder.decode(AppConfig.self, from: data)
    }

    public static func loadConfig() throws -> AppConfig {
        let url = try configURL()
        let data = try Data(contentsOf: url)
        return try configFromData(data)
    }

    public static func saveConfig(_ config: AppConfig) throws {
        let url = try configURL()
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(config)
        try data.write(to: url, options: .atomic)
    }

    public static func configURL() throws -> URL {
        if let override = configURLOverride {
            return override
        }
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw ConfigError.noApplicationSupportDirectory
        }
        return appSupport.appendingPathComponent("MahjongAdvisor/config.json")
    }
}
