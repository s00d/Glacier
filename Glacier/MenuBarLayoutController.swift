import AppKit

@MainActor
final class MenuBarLayoutController {

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

    private let glacierIcon: NSStatusItem
    private let sep1: NSStatusItem
    private let diamond: NSStatusItem
    private let sep2: NSStatusItem

    static func seedDefaultPositionsIfNeeded() {
        let ud = UserDefaults.standard
        if ud.object(forKey: DefaultsKey.iconPosition) == nil {
            ud.set(0, forKey: DefaultsKey.iconPosition)
        }
        if ud.object(forKey: DefaultsKey.separatorPosition) == nil {
            ud.set(1, forKey: DefaultsKey.separatorPosition)
        }
        if ud.object(forKey: DefaultsKey.diamondPosition) == nil {
            ud.set(2, forKey: DefaultsKey.diamondPosition)
        }
        if ud.object(forKey: DefaultsKey.secondSeparatorPosition) == nil {
            ud.set(3, forKey: DefaultsKey.secondSeparatorPosition)
        }
    }

    init(glacierIcon: NSStatusItem, sep1: NSStatusItem, diamond: NSStatusItem, sep2: NSStatusItem) {
        self.glacierIcon = glacierIcon
        self.sep1 = sep1
        self.diamond = diamond
        self.sep2 = sep2

        configureStaticAppearance()
    }

    func apply(state: GlacierState) {
        switch state {
        case .closed:
            applyClosedLayout()
        case .hiddenOpen:
            applyHiddenOpenLayout()
        case .allOpen, .editing:
            applyFullyOpenLayout()
        }

        updateIconAppearance(for: state)
    }

    func resetToDefaultPositions() {
        let ud = UserDefaults.standard
        ud.set(0, forKey: DefaultsKey.iconPosition)
        ud.set(1, forKey: DefaultsKey.separatorPosition)
        ud.set(2, forKey: DefaultsKey.diamondPosition)
        ud.set(3, forKey: DefaultsKey.secondSeparatorPosition)

        refreshPosition(for: glacierIcon, key: DefaultsKey.iconPosition)
        refreshPosition(for: sep1, key: DefaultsKey.separatorPosition)
        refreshPosition(for: diamond, key: DefaultsKey.diamondPosition)
        refreshPosition(for: sep2, key: DefaultsKey.secondSeparatorPosition)
    }

    private func configureStaticAppearance() {
        diamond.button?.image = symbolImage(
            named: Layout.diamondSymbol,
            description: "Glacier Always Hidden Marker"
        )
    }

    private func applyClosedLayout() {
        let ud = UserDefaults.standard
        let iconPos = ud.double(forKey: DefaultsKey.iconPosition)
        let newSep1Pos = iconPos + 1
        ud.set(newSep1Pos, forKey: DefaultsKey.separatorPosition)

        // Toggling visibility forces macOS to recalculate the separator position.
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

    private func refreshPosition(for item: NSStatusItem, key: String) {
        let position = UserDefaults.standard.double(forKey: key)
        item.isVisible = false
        UserDefaults.standard.set(position, forKey: key)
        item.isVisible = true
    }

    private func updateIconAppearance(for state: GlacierState) {
        guard let button = glacierIcon.button else { return }

        let symbolName: String
        let description: String

        switch state {
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
}
