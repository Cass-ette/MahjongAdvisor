import Foundation
import CoreGraphics
import ScreenCaptureKit
import MahjongCore
import MahjongOCR
import os

@MainActor
public final class OCRScheduler {
    private let state: AppState
    private let tracker: WindowTracker
    private let engine: OCREngine
    private let layout: LayoutTemplate
    private var task: Task<Void, Never>?
    private var cycleId: UInt64 = 0
    private var inFlight: Bool = false          // skip-if-busy guard
    private var consecutiveParseFailures: Int = 0  // for lobby detection
    private let lobbyDetectionThreshold = 3
    private let logger = Logger(subsystem: "com.example.MahjongAdvisor", category: "OCRScheduler")

    public init(
        state: AppState,
        tracker: WindowTracker,
        engine: OCREngine,
        layout: LayoutTemplate
    ) {
        self.state = state
        self.tracker = tracker
        self.engine = engine
        self.layout = layout
    }

    public func start(pollIntervalSeconds: Int) {
        stop()
        task = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { return }
                await self.tick()
                try? await Task.sleep(nanoseconds: UInt64(pollIntervalSeconds) * 1_000_000_000)
            }
        }
    }

    public func stop() {
        task?.cancel()
        task = nil
    }

    private func tick() async {
        // Skip-if-busy: if a previous cycle is still in flight, skip this tick.
        if inFlight { return }
        inFlight = true
        defer { inFlight = false }

        // Skip if paused or in lobby
        if state.mode == .paused || state.mode == .lobby { return }

        cycleId = cycleId &+ 1  // Increment first
        let currentCycleId = cycleId  // Then capture current value

        do {
            // 1. Find window
            guard let windowBounds = try await tracker.findMahjongSoulWindow() else {
                logger.debug("Mahjong Soul window not found")
                return
            }

            // 2. Capture screenshot
            let screenshot = try await captureWindow(bounds: windowBounds)

            // 3. OCR
            let result = try await engine.recognize(
                screenshot: screenshot,
                windowBounds: windowBounds,
                layout: layout
            )

            // 4. Discard stale results
            guard currentCycleId == self.cycleId else { return }

            // 5. Build hand + compute recommendations
            guard let hand = buildHand(from: result) else {
                // Couldn't parse a 14-tile hand
                consecutiveParseFailures += 1
                if consecutiveParseFailures >= lobbyDetectionThreshold {
                    state.mode = .lobby
                }
                return
            }
            consecutiveParseFailures = 0  // reset on success
            if state.mode == .lobby {
                state.mode = .collapsed  // we found a hand; back to normal
            }

            let ctx = RoundContext(
                discards: result.discards ?? [[], [], [], []],
                doraIndicators: result.doraIndicators ?? [],
                riichiDiscards: []
            )
            let recs = Recommend.compute(hand: hand, ctx: ctx)

            // 6. Update state
            self.state.update(ocrResult: result)
            self.state.update(recommendations: recs)
        } catch {
            logger.error("OCR cycle failed: \(error.localizedDescription)")
        }
    }

    private func captureWindow(bounds: CGRect) async throws -> CGImage {
        // Use ScreenCaptureKit to capture the window region
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        // FIXME: Window matching by frame equality is fragile due to floating-point precision.
        // Should match by window ID instead once WindowTracker provides it.
        guard let window = content.windows.first(where: { $0.frame == bounds }) else {
            throw NSError(domain: "OCRScheduler", code: 1, userInfo: [NSLocalizedDescriptionKey: "Window not found for capture"])
        }
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let config = SCStreamConfiguration()
        config.sourceRect = bounds
        config.width = Int(bounds.width)
        config.height = Int(bounds.height)
        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    }

    private func buildHand(from result: OCRResult) -> Hand? {
        guard let tiles = result.handTiles, tiles.count == 14 else { return nil }
        return Hand(
            closedTiles: tiles,
            melds: result.melds ?? [],
            seatWind: .east,  // TODO: extract from OCR
            roundWind: .east, // TODO
            isRiichi: false,
            remainingTiles: 70,  // TODO: extract
            redFivesRemaining: result.redFivesRemaining
        )
    }
}
