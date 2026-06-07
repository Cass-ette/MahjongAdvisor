import Foundation
import CoreGraphics
import AppKit

/// Tracks the Mahjong Soul game window for OCR processing.
/// Uses an actor to safely offload blocking CGWindowListCopyWindowInfo calls.
public actor WindowTracker {
    public init() {}

    /// Searches the on-screen window list for a Mahjong Soul / 雀魂 / Majsoul window.
    /// Returns the window's bounds (in screen coordinates) or nil if not found.
    /// Only returns windows on the primary display.
    public func findMahjongSoulWindow() async throws -> CGRect? {
        // Note: This must run on a background thread; CGWindowListCopyWindowInfo can block.
        return try await Task.detached(priority: .userInitiated) {
            guard let windowList = CGWindowListCopyWindowInfo(
                [.optionOnScreenOnly, .excludeDesktopElements],
                kCGNullWindowID
            ) as? [[String: Any]] else {
                return nil
            }

            let titles = ["雀魂", "Mahjong Soul", "Majsoul", "雀魂麻将"]
            for window in windowList {
                guard let ownerName = window[kCGWindowOwnerName as String] as? String else { continue }
                guard let windowTitle = window[kCGWindowName as String] as? String else { continue }
                let combined = "\(ownerName) \(windowTitle)"
                guard titles.contains(where: { combined.contains($0) }) else { continue }

                guard let boundsDict = window[kCGWindowBounds as String] as? [String: CGFloat],
                      let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) else {
                    continue
                }

                // Check that the window is on the primary display
                guard let primaryScreen = NSScreen.main else { continue }
                let primaryFrame = primaryScreen.frame
                if !primaryFrame.intersects(bounds) {
                    continue
                }

                return bounds
            }
            return nil
        }.value
    }

    /// Async stream of window bounds, polled at the given interval.
    /// Emits nil when no window is found, or the bounds when one is detected.
    public func windowBoundsStream(intervalSeconds: Double = 3.0) -> AsyncStream<CGRect?> {
        AsyncStream { continuation in
            let task = Task {
                while !Task.isCancelled {
                    let bounds = try? await findMahjongSoulWindow()
                    continuation.yield(bounds)
                    try? await Task.sleep(nanoseconds: UInt64(intervalSeconds * 1_000_000_000))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
