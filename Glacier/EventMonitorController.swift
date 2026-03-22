import AppKit

@MainActor
final class EventMonitorController {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var onInput: ((GlacierInput) -> Void)?

    func update(for state: GlacierState, onInput: @escaping (GlacierInput) -> Void) {
        self.onInput = onInput

        stopEventMonitors()
        guard state != .closed else { return }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self else { return event }
            guard event.keyCode == 53 else { return event } // Escape
            self.onInput?(.escape)
            return nil
        }

        guard state != .editing else { return }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
            [weak self] event in
            guard let self else { return }
            if event.modifierFlags.contains(.command) { return }

            MainActor.assumeIsolated {
                if self.shouldDismiss(forGlobalMouseEvent: event) {
                    self.onInput?(.dismiss)
                }
            }
        }
    }

    func invalidate() {
        onInput = nil
        stopEventMonitors()
    }

    private func stopEventMonitors() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    private func shouldDismiss(forGlobalMouseEvent event: NSEvent) -> Bool {
        !isPointInMenuBar(event.locationInWindow)
    }

    private func isPointInMenuBar(_ point: NSPoint) -> Bool {
        for screen in NSScreen.screens where screen.frame.contains(point) {
            let menuBarHeight = screen.frame.maxY - screen.visibleFrame.maxY
            guard menuBarHeight > 0 else { return false }

            let menuBarRect = NSRect(
                x: screen.frame.minX,
                y: screen.frame.maxY - menuBarHeight,
                width: screen.frame.width,
                height: menuBarHeight
            )
            return menuBarRect.contains(point)
        }

        return false
    }
}
