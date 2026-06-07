import Foundation
import CoreGraphics

/// Layout coordinates for OCR, stored as percentages of window bounds (DPI-independent).
public struct LayoutTemplate: Codable, Sendable {
    public var handRect: CGRect
    public var meldRect: CGRect
    public var discardRects: [CGRect]   // 4 rects, indexed by seat 0=East, 1=South, 2=West, 3=North
    public var doraRect: CGRect

    public init(handRect: CGRect, meldRect: CGRect, discardRects: [CGRect], doraRect: CGRect) {
        self.handRect = handRect
        self.meldRect = meldRect
        self.discardRects = discardRects
        self.doraRect = doraRect
    }

    /// Default layout for Mahjong Soul (approximate)
    public static let `default` = LayoutTemplate(
        handRect: CGRect(x: 0.05, y: 0.75, width: 0.6, height: 0.1),
        meldRect: CGRect(x: 0.05, y: 0.6, width: 0.6, height: 0.1),
        discardRects: [
            CGRect(x: 0.05, y: 0.4, width: 0.2, height: 0.1),
            CGRect(x: 0.3, y: 0.4, width: 0.2, height: 0.1),
            CGRect(x: 0.55, y: 0.4, width: 0.2, height: 0.1),
            CGRect(x: 0.8, y: 0.4, width: 0.2, height: 0.1),
        ],
        doraRect: CGRect(x: 0.05, y: 0.05, width: 0.1, height: 0.1)
    )
}
