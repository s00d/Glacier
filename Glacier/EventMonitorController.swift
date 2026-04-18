import AppKit

@MainActor
final class EventMonitorController {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var onInput: ((GlacierInput) -> Void)?
    private var dismissExclusionRects: () -> [NSRect] = { [] }

    private var menuTrackingDepth = 0

    init() {
        let center = NotificationCenter.default
        center.addObserver(
            forName: NSMenu.didBeginTrackingNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.menuTrackingDepth += 1 }
        }
        center.addObserver(
            forName: NSMenu.didEndTrackingNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.menuTrackingDepth = max(0, self.menuTrackingDepth - 1)
            }
        }
    }

    func update(
        for state: GlacierState,
        dismissExclusionRects: @escaping () -> [NSRect] = { [] },
        onInput: @escaping (GlacierInput) -> Void
    ) {
        self.dismissExclusionRects = dismissExclusionRects
        self.onInput = onInput

        stopEventMonitors()
        guard state != .closed else { return }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .leftMouseDown, .rightMouseDown]) {
            [weak self] event in
            guard let self else { return event }
            if event.type == .keyDown {
                guard event.keyCode == 53 else { return event } // Escape
                self.onInput?(.escape)
                return nil
            }
            guard state != .editing else { return event }
            guard !event.modifierFlags.contains(.command) else { return event }
            if self.shouldDismissAtMouseLocation() {
                self.onInput?(.dismiss)
            }
            return event
        }

        guard state != .editing else { return }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
            [weak self] event in
            guard let self else { return }
            if event.modifierFlags.contains(.command) { return }

            MainActor.assumeIsolated {
                if self.shouldDismissAtMouseLocation() {
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

    private func shouldDismissAtMouseLocation() -> Bool {
        if menuTrackingDepth > 0 { return false }

        let point = NSEvent.mouseLocation
        for rect in dismissExclusionRects() where rect.contains(point) {
            return false
        }

        return !isPointInMenuBar(point)
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
