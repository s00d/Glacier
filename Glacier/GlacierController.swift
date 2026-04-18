import AppKit
import ServiceManagement

@MainActor
final class GlacierController {

    // MARK: - State

    private var stateMachine = GlacierStateMachine()

    // MARK: - NSStatusItems

    private let glacierIcon: NSStatusItem  // ● user-facing icon
    private let sep1: NSStatusItem         // separator just left of ●
    private let diamond: NSStatusItem      // ◆ always-hidden boundary marker
    private let sep2: NSStatusItem         // separator just left of ◆

    // MARK: - Collaborators

    private let layoutController: MenuBarLayoutController
    private let eventMonitorController = EventMonitorController()

    // MARK: - Init

    init() {
        MenuBarLayoutController.seedDefaultPositionsIfNeeded()

        glacierIcon = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        glacierIcon.autosaveName = "GlacierIcon"

        sep1 = NSStatusBar.system.statusItem(withLength: 0)
        sep1.autosaveName = "GlacierSep"

        diamond = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        diamond.autosaveName = "GlacierDiamond"

        sep2 = NSStatusBar.system.statusItem(withLength: 0)
        sep2.autosaveName = "GlacierSep2"

        layoutController = MenuBarLayoutController(
            glacierIcon: glacierIcon,
            sep1: sep1,
            diamond: diamond,
            sep2: sep2
        )

        // ● icon button
        if let button = glacierIcon.button {
            button.target = self
            button.action = #selector(primaryControlClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        if let button = diamond.button {
            button.target = self
            button.action = #selector(boundaryControlClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        sep1.button?.cell?.isEnabled = false
        sep2.button?.cell?.isEnabled = false

        applyCurrentState()
    }

    // MARK: - State Transitions

    private func applyCurrentState() {
        layoutController.apply(state: stateMachine.state)
        eventMonitorController.update(for: stateMachine.state) { [weak self] input in
            self?.handle(input)
        }
    }

    private func handle(_ input: GlacierInput) {
        stateMachine.handle(input)
        applyCurrentState()
    }

    // MARK: - Click Handling

    @objc private func primaryControlClicked(_ sender: NSStatusBarButton) {
        handleControlClick(isBoundary: false)
    }

    @objc private func boundaryControlClicked(_ sender: NSStatusBarButton) {
        handleControlClick(isBoundary: true)
    }

    private func handleControlClick(isBoundary: Bool) {
        guard let event = NSApp.currentEvent else { return }

        if event.modifierFlags.contains(.command) { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else if event.modifierFlags.contains(.option) {
            handle(.alternateClick)
        } else if isBoundary {
            handle(.boundaryClick)
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

        let launchAtLoginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        launchAtLoginItem.state = isLaunchAtLoginEnabled() ? .on : .off
        menu.addItem(launchAtLoginItem)

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
            "Click ◆ after opening hidden\nShow / hide items left of ◆",
            "Option + Click ● or ◆\nShow / hide always-hidden section",
            "Press Esc or click below the menu bar\nHide open sections",
            "Right-click ● or ◆\nUsage, Edit Layout, Reset Layout, Quit",
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
        layoutController.resetToDefaultPositions()
        handle(.finishEditing)
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if isLaunchAtLoginEnabled() {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Unable to Update Launch at Login"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private func isLaunchAtLoginEnabled() -> Bool {
        SMAppService.mainApp.status == .enabled
    }
}
