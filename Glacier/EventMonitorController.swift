import AppKit

@MainActor
final class EventMonitorController {
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
    }

    func invalidate() {
        onInput = nil
        stopEventMonitors()
    }

    private func stopEventMonitors() {
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        localMonitor = nil
    }
}
