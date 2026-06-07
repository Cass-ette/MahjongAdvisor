import Foundation
import CoreGraphics
import MahjongCore

/// Protocol for OCR engines that can recognize mahjong tile layouts.
public protocol OCREngine: Sendable {
    /// Recognize tiles in a screenshot using the given layout template.
    /// - Parameters:
    ///   - screenshot: Captured window screenshot
    ///   - windowBounds: Position and size of the source window
    ///   - layout: Layout template with normalized regions
    /// - Returns: OCR result with recognized tiles and confidence scores
    func recognize(
        screenshot: CGImage,
        windowBounds: CGRect,
        layout: LayoutTemplate
    ) async throws -> OCRResult
}
