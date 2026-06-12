import AppKit
import SwiftUI
import MahjongCore
import MahjongOCR

@MainActor
final class AppDelegateAdaptor: NSObject, NSApplicationDelegate {
    private var state: AppState!
    private var panel: FloatingPanel!
    private var scheduler: OCRScheduler!
    private var keyInterceptor: KeyInterceptor!
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. State
        state = AppState()

        // 2. Load config
        let config = (try? ConfigStore.loadConfig()) ?? AppConfig()

        // 3. Load layout
        let layoutURL = layoutURL()
        let layout: LayoutTemplate = (try? LayoutTemplate(from: Data(contentsOf: layoutURL))) ?? defaultLayout()

        // 4. Tracker + engine + scheduler
        let tracker = WindowTracker()
        let engine = VisionOCREngine()
        scheduler = OCRScheduler(state: state, tracker: tracker, engine: engine, layout: layout)
        scheduler.start(pollIntervalSeconds: config.pollIntervalSeconds)

        // 5. Floating panel
        panel = FloatingPanel(
            contentRect: NSRect(x: config.panelPosition.x, y: config.panelPosition.y, width: 280, height: 80)
        )
        panel.setContent {
            PanelContentView(state: self.state) {
                self.state.mode = self.state.mode == .collapsed ? .expanded : .collapsed
            }
        }
        panel.makeKeyAndOrderFront(nil)

        // 6. Key interceptor for Edit Mode
        keyInterceptor = KeyInterceptor()
        keyInterceptor.install { [unowned self] event in
            return self.handleKey(event) ?? event
        }

        // 7. Menu bar
        setupMenuBar()

        // 8. Activate
        NSApp.setActivationPolicy(.accessory)
    }

    private func handleKey(_ event: NSEvent) -> NSEvent? {
        // ⌘⇧E: toggle Edit Mode (works from any mode except paused/lobby)
        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if mods.contains(.command) && mods.contains(.shift),
           event.charactersIgnoringModifiers?.lowercased() == "e" {
            if state.mode != .paused && state.mode != .lobby {
                state.mode = state.mode == .editing ? .collapsed : .editing
            }
            return nil  // swallow the key
        }

        // When in Edit Mode, intercept keys for hotkey editing
        guard state.mode == .editing else { return event }

        // ... TODO: implement tile editing (←/→, 1-9, M/P/S/Z, Esc)
        // For v1, just return the event unchanged so the rest of the keyboard works
        return event
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "tortoise.fill", accessibilityDescription: "MahjongAdvisor")

        let menu = NSMenu()
        let pauseItem = NSMenuItem(title: "暂停/继续  ⌘⇧P", action: #selector(togglePause), keyEquivalent: "p")
        pauseItem.keyEquivalentModifierMask = [.command, .shift]
        menu.addItem(pauseItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "校准窗口布局", action: #selector(recalibrate), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "设置...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    @objc private func togglePause() { state.togglePause() }
    @objc private func recalibrate() { /* TODO: open RecalibrateFlow */ }
    @objc private func openSettings() { /* TODO: open SettingsView */ }
    @objc private func quit() { NSApp.terminate(nil) }

    private func layoutURL() -> URL {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("Application Support directory unavailable")
        }
        return appSupport.appendingPathComponent("MahjongAdvisor/layout.json")
    }

    private func defaultLayout() -> LayoutTemplate {
        return LayoutTemplate(
            handRect: CGRect(x: 0.05, y: 0.75, width: 0.6, height: 0.1),
            meldRect: CGRect(x: 0.05, y: 0.6, width: 0.6, height: 0.1),
            discardRects: [
                CGRect(x: 0.05, y: 0.3, width: 0.2, height: 0.2),
                CGRect(x: 0.3, y: 0.3, width: 0.2, height: 0.2),
                CGRect(x: 0.55, y: 0.3, width: 0.2, height: 0.2),
                CGRect(x: 0.8, y: 0.3, width: 0.2, height: 0.2),
            ],
            doraRect: CGRect(x: 0.05, y: 0.05, width: 0.1, height: 0.1)
        )
    }
}

extension LayoutTemplate {
    init(from data: Data) throws {
        self = try JSONDecoder().decode(LayoutTemplate.self, from: data)
    }
}
