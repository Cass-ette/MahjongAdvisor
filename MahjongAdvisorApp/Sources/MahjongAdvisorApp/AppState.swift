import Foundation
import Observation
import MahjongCore
import MahjongOCR

public enum AppMode: Sendable {
    case collapsed
    case expanded
    case editing
    case paused
    case lobby
}

@Observable
@MainActor
public final class AppState {
    public var ocrResult: OCRResult?
    public var recommendations: [Recommendation] = []
    public var mode: AppMode = .collapsed
    public var lastRecommendation: Recommendation? {
        recommendations.first
    }

    public init() {}

    public func update(ocrResult: OCRResult) {
        self.ocrResult = ocrResult
        // Auto-enter Edit Mode if hand or dora confidence is low
        if ocrResult.confidence.hand < 0.7 || ocrResult.confidence.dora < 0.7 {
            if mode != .paused && mode != .lobby {
                mode = .editing
            }
        }
    }

    public func update(recommendations: [Recommendation]) {
        self.recommendations = recommendations
    }

    /// Toggles between paused and active modes.
    /// When pausing, enters `.paused` state. When unpausing, always returns to `.collapsed`.
    /// Note: This does not preserve the previous mode state.
    public func togglePause() {
        switch mode {
        case .paused:
            mode = .collapsed
        case .collapsed, .expanded, .editing, .lobby:
            mode = .paused
        }
    }
}
