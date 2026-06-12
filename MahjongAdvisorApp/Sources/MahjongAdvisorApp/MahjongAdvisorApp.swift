import SwiftUI
import MahjongCore
import MahjongOCR

@main
struct MahjongAdvisorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegateAdaptor.self) var appDelegate

    var body: some Scene {
        // No main scene; the floating panel is managed by AppDelegate.
        Settings {
            EmptyView()
        }
    }
}
