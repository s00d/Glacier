import AppKit

@MainActor
final class MenuBarLayoutController {

    private enum Layout {
        /// Must be large enough to push items off-screen; values beyond ~10k have been the stable default.
        static let hiddenLength: CGFloat = 10_000
        /// When expanded, the separator has no content — `variableLength` still reserves a few pixels; use `0` to tighten the gap next to the tray icon.
        static let openSeparatorLength: CGFloat = 0
        /// Logical size for the three-dots tray icon (points); tight width — background hugs the dots.
        static let trayIconSize = NSSize(width: 18, height: 11)
    }

    private enum DefaultsKey {
        static let iconPosition = "NSStatusItem Preferred Position GlacierIcon"
        static let separatorPosition = "NSStatusItem Preferred Position GlacierSep"
    }

    private let glacierIcon: NSStatusItem
    private let sep1: NSStatusItem

    static func seedDefaultPositionsIfNeeded() {
        let ud = UserDefaults.standard
        if ud.object(forKey: DefaultsKey.iconPosition) == nil {
            ud.set(0, forKey: DefaultsKey.iconPosition)
        }
        if ud.object(forKey: DefaultsKey.separatorPosition) == nil {
            ud.set(1, forKey: DefaultsKey.separatorPosition)
        }
        sanitizeStoredPositionsIfNeeded()
    }

    /// Guard against corrupted UserDefaults values from OS upgrades or manual edits.
    private static func sanitizeStoredPositionsIfNeeded() {
        let ud = UserDefaults.standard
        let defaults: [(String, Double)] = [
            (DefaultsKey.iconPosition, 0),
            (DefaultsKey.separatorPosition, 1),
        ]
        for (key, fallback) in defaults {
            let raw = ud.double(forKey: key)
            if raw.isNaN || raw.isInfinite || raw < 0 || raw > 50_000 {
                ud.set(fallback, forKey: key)
            }
        }
    }

    private static func clampedStatusPosition(_ raw: Double, fallback: Double) -> Double {
        if raw.isNaN || raw.isInfinite || raw < 0 { return fallback }
        return min(raw, 50_000)
    }

    init(glacierIcon: NSStatusItem, sep1: NSStatusItem) {
        self.glacierIcon = glacierIcon
        self.sep1 = sep1
    }

    func apply(state: GlacierState) {
        switch state {
        case .closed:
            applyClosedLayout()
        case .open, .editing:
            applyOpenLayout()
        }

        updateIconAppearance(for: state)
    }

    func resetToDefaultPositions() {
        let ud = UserDefaults.standard
        ud.set(0, forKey: DefaultsKey.iconPosition)
        ud.set(1, forKey: DefaultsKey.separatorPosition)

        refreshPosition(for: glacierIcon, key: DefaultsKey.iconPosition)
        refreshPosition(for: sep1, key: DefaultsKey.separatorPosition)
    }

    private func applyClosedLayout() {
        let ud = UserDefaults.standard
        let iconPos = Self.clampedStatusPosition(ud.double(forKey: DefaultsKey.iconPosition), fallback: 0)
        let newSep1Pos = iconPos + 1
        ud.set(newSep1Pos, forKey: DefaultsKey.separatorPosition)

        runStatusBarLayoutTransaction {
            sep1.isVisible = false
            ud.set(newSep1Pos, forKey: DefaultsKey.separatorPosition)
            sep1.isVisible = true
        }

        sep1.length = Layout.hiddenLength
    }

    private func applyOpenLayout() {
        sep1.length = Layout.openSeparatorLength
    }

    private func refreshPosition(for item: NSStatusItem, key: String, fallback: Double = 0) {
        let raw = UserDefaults.standard.double(forKey: key)
        let position = Self.clampedStatusPosition(raw, fallback: fallback)
        if position != raw {
            UserDefaults.standard.set(position, forKey: key)
        }
        runStatusBarLayoutTransaction {
            item.isVisible = false
            UserDefaults.standard.set(position, forKey: key)
            item.isVisible = true
        }
    }

    /// Batches `isVisible` toggles so AppKit can coalesce status-bar relayout where possible.
    private func runStatusBarLayoutTransaction(_ updates: () -> Void) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0
            context.allowsImplicitAnimation = false
            updates()
        }
    }

    private func updateIconAppearance(for state: GlacierState) {
        guard let button = glacierIcon.button else { return }

        let description: String
        let prominentBackground: Bool

        switch state {
        case .closed:
            description = "Glacier Closed"
            prominentBackground = false
        case .open:
            description = "Glacier Hidden Icons Shown"
            prominentBackground = true
        case .editing:
            description = "Glacier Editing Layout"
            prominentBackground = true
        }

        let image = Self.trayDotsImage(
            prominentBackground: prominentBackground,
            accessibilityDescription: description
        )
        image.isTemplate = false
        button.image = image
        button.toolTip = description
    }

    /// Three thick dots: closed = solid; open/editing = tight white pill + each dot black ring with white center.
    private static func trayDotsImage(prominentBackground: Bool, accessibilityDescription: String) -> NSImage {
        let size = Layout.trayIconSize
        let image = NSImage(size: size, flipped: false) { rect in
            let w = rect.width
            let h = rect.height
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }

            ctx.saveGState()
            defer { ctx.restoreGState() }

            let midX = w * 0.5
            let midY = h * 0.5
            /// Larger, heavier dots (outer radius in points).
            let dotOuterR: CGFloat = 2.35
            /// Space between adjacent dot centers (compact row).
            let centerPitch: CGFloat = 4.4
            let centers: [CGFloat] = [midX - centerPitch, midX, midX + centerPitch]

            let leftX = centers[0] - dotOuterR
            let rightX = centers[2] + dotOuterR
            let topY = midY - dotOuterR
            let bottomY = midY + dotOuterR

            if prominentBackground {
                let padH: CGFloat = 1.0
                let padV: CGFloat = 0.65
                let pillRect = NSRect(
                    x: leftX - padH,
                    y: topY - padV,
                    width: rightX - leftX + padH * 2,
                    height: bottomY - topY + padV * 2
                )
                let corner = min(pillRect.height * 0.45, 3.0)
                let pill = NSBezierPath(roundedRect: pillRect, xRadius: corner, yRadius: corner)
                NSColor.white.setFill()
                pill.fill()
                NSColor.black.withAlphaComponent(0.14).setStroke()
                pill.lineWidth = 0.5
                pill.stroke()
            }

            let closedDotColor: NSColor = {
                let darkMenu =
                    NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                return darkMenu ? .white : .black
            }()

            for cx in centers {
                if prominentBackground {
                    let outer = NSBezierPath(
                        ovalIn: CGRect(
                            x: cx - dotOuterR,
                            y: midY - dotOuterR,
                            width: dotOuterR * 2,
                            height: dotOuterR * 2
                        )
                    )
                    NSColor.black.setFill()
                    outer.fill()
                    let innerR = dotOuterR * 0.52
                    let inner = NSBezierPath(
                        ovalIn: CGRect(
                            x: cx - innerR,
                            y: midY - innerR,
                            width: innerR * 2,
                            height: innerR * 2
                        )
                    )
                    NSColor.white.setFill()
                    inner.fill()
                } else {
                    closedDotColor.setFill()
                    let dot = NSBezierPath(
                        ovalIn: CGRect(
                            x: cx - dotOuterR,
                            y: midY - dotOuterR,
                            width: dotOuterR * 2,
                            height: dotOuterR * 2
                        )
                    )
                    dot.fill()
                }
            }

            return true
        }
        image.accessibilityDescription = accessibilityDescription
        return image
    }
}
