import XCTest
@testable import MahjongOCR
import CoreGraphics

final class WindowTrackerTests: XCTestCase {
    /// This test requires a real Mahjong Soul window. Skipped on CI.
    /// Run locally with: `swift test --filter WindowTrackerTests`
    func testFindsMahjongSoulWindow() async throws {
        try XCTSkipIf(isCI, "WindowTracker requires a real window; skipping on CI")

        let tracker = WindowTracker()
        let bounds = try await tracker.findMahjongSoulWindow()
        // We don't assert specific bounds; just that the call doesn't throw
        // and returns nil (if no window) or a valid CGRect.
        if let bounds = bounds {
            XCTAssertGreaterThan(bounds.width, 0)
            XCTAssertGreaterThan(bounds.height, 0)
        }
    }

    private var isCI: Bool {
        return ProcessInfo.processInfo.environment["CI"] != nil
    }
}
