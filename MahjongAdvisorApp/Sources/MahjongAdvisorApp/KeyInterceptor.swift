import AppKit

public final class KeyInterceptor {
    private var monitor: Any?
    private var onKey: ((NSEvent) -> NSEvent?)?

    public init() {}

    /// Installs a local event monitor. The handler is called for every keyDown event.
    /// Returning nil swallows the event; returning the event passes it through.
    public func install(handler: @escaping (NSEvent) -> NSEvent?) {
        self.onKey = handler
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            return self?.onKey?(event) ?? event
        }
    }

    public func uninstall() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        self.onKey = nil
    }

    deinit {
        uninstall()
    }
}
