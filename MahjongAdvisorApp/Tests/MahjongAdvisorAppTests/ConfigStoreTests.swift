import XCTest
@testable import MahjongAdvisorApp

final class ConfigStoreTests: XCTestCase {
    func testLoadConfigFromJSON() throws {
        let json = """
        {
          "pollIntervalSeconds": 5,
          "panelPosition": {"x": 200, "y": 300},
          "panelMode": "expanded",
          "logLevel": "debug"
        }
        """
        let data = json.data(using: .utf8)!
        let config = try ConfigStore.configFromData(data)
        XCTAssertEqual(config.pollIntervalSeconds, 5)
        XCTAssertEqual(config.panelPosition.x, 200)
        XCTAssertEqual(config.panelPosition.y, 300)
        XCTAssertEqual(config.panelMode, .expanded)
        XCTAssertEqual(config.logLevel, "debug")
    }

    func testLoadConfigWithDefaults() throws {
        let json = "{}"
        let data = json.data(using: .utf8)!
        let config = try ConfigStore.configFromData(data)
        XCTAssertEqual(config.pollIntervalSeconds, 3)
        XCTAssertEqual(config.panelPosition.x, 100)
        XCTAssertEqual(config.panelPosition.y, 200)
        XCTAssertEqual(config.panelMode, .collapsed)
        XCTAssertEqual(config.logLevel, "info")
    }

    func testSaveAndLoadConfigIntegration() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("MahjongAdvisorTest-\(UUID().uuidString)")
        let tempConfigURL = tempDir.appendingPathComponent("config.json")

        // Set override to use temp directory
        ConfigStore.configURLOverride = tempConfigURL

        // Create a custom config
        let originalConfig = AppConfig(
            pollIntervalSeconds: 10,
            panelPosition: PanelPosition(x: 500, y: 600),
            panelMode: .expanded,
            logLevel: "trace"
        )

        // Save using ConfigStore.saveConfig() - this tests directory creation
        try ConfigStore.saveConfig(originalConfig)

        // Load back using ConfigStore.loadConfig()
        let loadedConfig = try ConfigStore.loadConfig()

        XCTAssertEqual(loadedConfig.pollIntervalSeconds, 10)
        XCTAssertEqual(loadedConfig.panelPosition.x, 500)
        XCTAssertEqual(loadedConfig.panelPosition.y, 600)
        XCTAssertEqual(loadedConfig.panelMode, .expanded)
        XCTAssertEqual(loadedConfig.logLevel, "trace")

        // Cleanup
        ConfigStore.configURLOverride = nil
        try? FileManager.default.removeItem(at: tempDir)
    }
}
