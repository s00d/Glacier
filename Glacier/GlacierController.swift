import AppKit

private nonisolated func seedDefaultPositionsIfNeeded() {
    let ud = UserDefaults.standard
    if ud.object(forKey: "NSStatusItem Preferred Position GlacierIcon") == nil {
        ud.set(0, forKey: "NSStatusItem Preferred Position GlacierIcon")
    }
    if ud.object(forKey: "NSStatusItem Preferred Position GlacierSep") == nil {
        ud.set(1, forKey: "NSStatusItem Preferred Position GlacierSep")
    }
    if ud.object(forKey: "NSStatusItem Preferred Position GlacierDiamond") == nil {
        ud.set(2, forKey: "NSStatusItem Preferred Position GlacierDiamond")
    }
    if ud.object(forKey: "NSStatusItem Preferred Position GlacierSep2") == nil {
        ud.set(3, forKey: "NSStatusItem Preferred Position GlacierSep2")
    }
}

@MainActor
final class GlacierController {

    // MARK: - Layout Constants

    private enum Layout {
        static let hiddenLength: CGFloat = 10_000
        static let closedSymbol = "circle.fill"
        static let hiddenOpenSymbol = "circle.lefthalf.filled"
        static let allOpenSymbol = "circle.grid.3x3.fill"
        static let editingSymbol = "slider.horizontal.3"
        static let diamondSymbol = "diamond.fill"
    }

    private enum DefaultsKey {
        static let iconPosition = "NSStatusItem Preferred Position GlacierIcon"
        static let separatorPosition = "NSStatusItem Preferred Position GlacierSep"
        static let diamondPosition = "NSStatusItem Preferred Position GlacierDiamond"
        static let secondSeparatorPosition = "NSStatusItem Preferred Position GlacierSep2"
    }

    // MARK: - State

    private var stateMachine = GlacierStateMachine()

    // MARK: - NSStatusItems

    private let glacierIcon: NSStatusItem  // ● user-facing icon
    private let sep1: NSStatusItem         // separator just left of ●
    private let diamond: NSStatusItem      // ◆ always-hidden boundary marker
    private let sep2: NSStatusItem         // separator just left of ◆

    // MARK: - Event Monitors

    private var globalMonitor: Any?
    private var localMonitor: Any?

    // MARK: - Init

    init() {
        seedDefaultPositionsIfNeeded()

        glacierIcon = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        glacierIcon.autosaveName = "GlacierIcon"

        sep1 = NSStatusBar.system.statusItem(withLength: 0)
        sep1.autosaveName = "GlacierSep"

        diamond = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        diamond.autosaveName = "GlacierDiamond"

        sep2 = NSStatusBar.system.statusItem(withLength: 0)
        sep2.autosaveName = "GlacierSep2"

        // ● icon button
        if let button = glacierIcon.button {
            button.target = self
            button.action = #selector(iconClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // ◆ diamond marker (non-clickable)
        if let button = diamond.button {
            button.image = symbolImage(
                named: Layout.diamondSymbol,
                description: "Glacier Always Hidden Marker"
            )
            button.cell?.isEnabled = false
        }

        sep1.button?.cell?.isEnabled = false
        sep2.button?.cell?.isEnabled = false

        applyCurrentState()
    }

    // MARK: - State Transitions

    private func applyCurrentState() {
        switch stateMachine.state {
        case .closed:
            applyClosedLayout()
        case .hiddenOpen:
            applyHiddenOpenLayout()
        case .allOpen, .editing:
            applyFullyOpenLayout()
        }

        updateIconAppearance()
        updateEventMonitors()
    }

    private func handle(_ input: GlacierInput) {
        stateMachine.handle(input)
        applyCurrentState()
    }

    private func applyClosedLayout() {
        let ud = UserDefaults.standard
        let iconPos = ud.double(forKey: DefaultsKey.iconPosition)
        let newSep1Pos = iconPos + 1
        ud.set(newSep1Pos, forKey: DefaultsKey.separatorPosition)

        // isVisible toggle forces macOS to recalculate position
        sep1.isVisible = false
        ud.set(newSep1Pos, forKey: DefaultsKey.separatorPosition)
        sep1.isVisible = true

        sep1.length = Layout.hiddenLength
        sep2.length = NSStatusItem.variableLength
    }

    private func applyHiddenOpenLayout() {
        sep1.length = NSStatusItem.variableLength

        let ud = UserDefaults.standard
        let diamondPos = ud.double(forKey: DefaultsKey.diamondPosition)
        let newSep2Pos = diamondPos + 1
        ud.set(newSep2Pos, forKey: DefaultsKey.secondSeparatorPosition)

        sep2.isVisible = false
        ud.set(newSep2Pos, forKey: DefaultsKey.secondSeparatorPosition)
        sep2.isVisible = true

        sep2.length = Layout.hiddenLength
    }

    private func applyFullyOpenLayout() {
        sep1.length = NSStatusItem.variableLength
        sep2.length = NSStatusItem.variableLength
    }

    // MARK: - Click Handling

    @objc private func iconClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.modifierFlags.contains(.command) { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else if event.modifierFlags.contains(.option) {
            handle(.alternateClick)
        } else {
            handle(.primaryClick)
        }
    }

    // MARK: - Context Menu

    private func showContextMenu() {
        let menu = NSMenu()

        let usageItem = NSMenuItem(title: "Usage", action: #selector(showUsage), keyEquivalent: "")
        usageItem.target = self
        menu.addItem(usageItem)

        let editTitle = stateMachine.state == .editing ? "Done Editing" : "Edit Layout"
        let editItem = NSMenuItem(title: editTitle, action: #selector(toggleEditingMode), keyEquivalent: "")
        editItem.target = self
        menu.addItem(editItem)

        let resetItem = NSMenuItem(title: "Reset Layout", action: #selector(resetLayout), keyEquivalent: "")
        resetItem.target = self
        menu.addItem(resetItem)

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: "Quit Glacier",
            action: #selector(NSApp.terminate(_:)),
            keyEquivalent: "q"
        ))
        if let button = glacierIcon.button {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.maxY + 5), in: button)
        }
    }

    @objc private func showUsage() {
        let paragraphs = [
            "[Always Hidden] ◆ [Hidden] ● [Visible]",
            "Click ●\nShow / hide hidden section",
            "Option + Click ●\nShow / hide always-hidden section",
            "Press Esc or click below the menu bar\nHide open sections",
            "Right-click ●\nUsage, Edit Layout, Reset Layout, Quit",
            "Edit Layout + Cmd + Drag ● ◆\nRearrange sections",
        ]

        let font = NSFont.systemFont(ofSize: 12)
        let boldFont = NSFont.boldSystemFont(ofSize: 12)
        let monoFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let result = NSMutableAttributedString()

        // Layout diagram
        let diagram = NSAttributedString(
            string: paragraphs[0] + "\n\n",
            attributes: [.font: monoFont, .foregroundColor: NSColor.secondaryLabelColor]
        )
        result.append(diagram)

        // Action items
        for i in 1..<paragraphs.count {
            let parts = paragraphs[i].split(separator: "\n", maxSplits: 1)
            let action = NSAttributedString(string: String(parts[0]) + "\n", attributes: [.font: boldFont])
            let desc = NSAttributedString(string: String(parts[1]), attributes: [.font: font, .foregroundColor: NSColor.secondaryLabelColor])
            result.append(action)
            result.append(desc)
            if i < paragraphs.count - 1 {
                result.append(NSAttributedString(string: "\n\n"))
            }
        }

        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 260, height: 0))
        textView.isEditable = false
        textView.isSelectable = false
        textView.drawsBackground = false
        textView.textStorage?.setAttributedString(result)
        textView.sizeToFit()

        let alert = NSAlert()
        alert.messageText = "Glacier Usage"
        alert.informativeText = ""
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.accessoryView = textView
        alert.runModal()
    }

    @objc private func toggleEditingMode() {
        if stateMachine.state == .editing {
            handle(.finishEditing)
        } else {
            handle(.enterEditing)
        }
    }

    @objc private func resetLayout() {
        let ud = UserDefaults.standard
        ud.set(0, forKey: DefaultsKey.iconPosition)
        ud.set(1, forKey: DefaultsKey.separatorPosition)
        ud.set(2, forKey: DefaultsKey.diamondPosition)
        ud.set(3, forKey: DefaultsKey.secondSeparatorPosition)

        refreshPosition(for: glacierIcon, key: DefaultsKey.iconPosition)
        refreshPosition(for: sep1, key: DefaultsKey.separatorPosition)
        refreshPosition(for: diamond, key: DefaultsKey.diamondPosition)
        refreshPosition(for: sep2, key: DefaultsKey.secondSeparatorPosition)

        handle(.finishEditing)
    }

    // MARK: - Event Monitors

    private func updateEventMonitors() {
        stopEventMonitors()
        guard stateMachine.state != .closed else { return }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self else { return event }
            guard event.keyCode == 53 else { return event } // Escape
            self.handle(.escape)
            return nil
        }

        guard stateMachine.state != .editing else { return }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
            [weak self] event in
            if event.modifierFlags.contains(.command) { return }
            MainActor.assumeIsolated {
                guard let self else { return }
                if self.shouldDismiss(forGlobalMouseEvent: event) {
                    self.handle(.dismiss)
                }
            }
        }
    }

    private func stopEventMonitors() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }

    // MARK: - Helpers

    private func refreshPosition(for item: NSStatusItem, key: String) {
        let position = UserDefaults.standard.double(forKey: key)
        item.isVisible = false
        UserDefaults.standard.set(position, forKey: key)
        item.isVisible = true
    }

    private func updateIconAppearance() {
        guard let button = glacierIcon.button else { return }

        let symbolName: String
        let description: String

        switch stateMachine.state {
        case .closed:
            symbolName = Layout.closedSymbol
            description = "Glacier Closed"
        case .hiddenOpen:
            symbolName = Layout.hiddenOpenSymbol
            description = "Glacier Hidden Section Open"
        case .allOpen:
            symbolName = Layout.allOpenSymbol
            description = "Glacier All Sections Open"
        case .editing:
            symbolName = Layout.editingSymbol
            description = "Glacier Editing Layout"
        }

        button.image = symbolImage(named: symbolName, description: description)
        button.toolTip = description
    }

    private func symbolImage(named name: String, description: String) -> NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: 9, weight: .regular)
        let image = NSImage(systemSymbolName: name, accessibilityDescription: description)
            ?? NSImage(systemSymbolName: Layout.closedSymbol, accessibilityDescription: description)
        return image?.withSymbolConfiguration(config)
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
