import AppKit
import SwiftUI

public final class FloatingPanel: NSPanel {
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .resizable, .closable, .nonactivatingPanel, .hudWindow, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isMovableByWindowBackground = true  // drag on background
        self.hidesOnDeactivate = false
        self.becomesKeyOnlyIfNeeded = true
        self.title = "MahjongAdvisor"
        self.titlebarAppearsTransparent = true
    }

    public func setContent<V: View>(@ViewBuilder content: () -> V) {
        self.contentView = NSHostingView(rootView: content())
    }

    /// Allow key events only when explicitly required (edit mode).
    public override var canBecomeKey: Bool {
        return true  // Edit mode needs this; KeyInterceptor handles suppression
    }
}
