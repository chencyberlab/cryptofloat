import Cocoa

// MARK: - Toggle Button View
class ToggleButtonView: NSView {
    var isHovered = false
    var isExpanded = true {
        didSet {
            setAccessibilityValueAndNotify(isExpanded ? "Expanded" : "Collapsed")
        }
    }
    var onClick: (() -> Void)?
    var backgroundOpacity: CGFloat = 0.85 {
        didSet { needsDisplay = true }
    }

    /// 24h change of the primary coin; tints the ring green/red as an ambient signal.
    var accentChange: Double = 0 {
        didSet { needsDisplay = true }
    }

    private var trackingArea: NSTrackingArea?
    private var dragStartMouseLocation: NSPoint?
    private var dragStartWindowOrigin: NSPoint?
    private var didDragWindow = false

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        setupTrackingArea()
        configureAccessibility()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupTrackingArea()
        configureAccessibility()
    }

    override var mouseDownCanMoveWindow: Bool { false }
    override var acceptsFirstResponder: Bool { true }

    override func becomeFirstResponder() -> Bool {
        let accepted = super.becomeFirstResponder()
        needsDisplay = true
        return accepted
    }

    override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        needsDisplay = true
        return resigned
    }

    private func configureAccessibility() {
        toolTip = "Expand or collapse cryptocurrency prices"
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel("CryptoFloat prices")
        setAccessibilityHelp("Expands or collapses the cryptocurrency price panel.")
        setAccessibilityValue(isExpanded ? "Expanded" : "Collapsed")
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    private func setupTrackingArea() {
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    private func accentRingColor() -> NSColor {
        let strong: CGFloat = isHovered ? 0.9 : 0.6
        let theme = ThemeCatalog.current
        if accentChange > 0.05 {
            return theme.positive.color(alpha: strong)
        } else if accentChange < -0.05 {
            return theme.negative.color(alpha: strong)
        } else {
            return theme.accent.color(alpha: isHovered ? 0.85 : 0.45)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let circleRect = bounds.insetBy(dx: 3, dy: 3)
        let path = NSBezierPath(ovalIn: circleRect)
        let opacity = accessibilityAdjustedOpacity(backgroundOpacity)

        // Soft outer glow on hover
        if isHovered {
            let glow = NSBezierPath(ovalIn: bounds.insetBy(dx: 0.5, dy: 0.5))
            ThemeCatalog.current.accent.color(alpha: 0.18 * opacity).setStroke()
            glow.lineWidth = 3
            glow.stroke()
        }

        // Vertical gradient fill for depth
        let top: NSColor
        let bottom: NSColor
        let theme = ThemeCatalog.current
        if NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency {
            top = theme.background.color()
            bottom = theme.backgroundDark.color()
        } else if isHovered {
            top = (
                theme.background.color().blended(
                    withFraction: 0.30,
                    of: theme.accent.color()
                ) ?? theme.background.color()
            ).withAlphaComponent(opacity)
            bottom = theme.background.color(alpha: opacity)
        } else {
            top = theme.background.color(alpha: opacity)
            bottom = theme.backgroundDark.color(alpha: opacity)
        }
        if let gradient = NSGradient(starting: top, ending: bottom) {
            gradient.draw(in: path, angle: -90)
        } else {
            bottom.setFill()
            path.fill()
        }

        // Accent ring (reflects market direction)
        let ringColor = accentRingColor()
        ringColor.withAlphaComponent(ringColor.alphaComponent * opacity).setStroke()
        path.lineWidth = isHovered ? 2 : 1.5
        path.stroke()

        // ₿ glyph with a subtle shadow
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
        shadow.shadowBlurRadius = 2
        shadow.shadowOffset = NSSize(width: 0, height: -1)

        let symbol = "₿"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 19, weight: .semibold),
            .foregroundColor: ThemeCatalog.current.foreground.color(),
            .shadow: shadow
        ]
        let size = symbol.size(withAttributes: attributes)
        let point = NSPoint(
            x: (bounds.width - size.width) / 2,
            y: (bounds.height - size.height) / 2
        )
        symbol.draw(at: point, withAttributes: attributes)

        if window?.firstResponder === self {
            NSColor.keyboardFocusIndicatorColor.setStroke()
            let focusPath = NSBezierPath(ovalIn: bounds.insetBy(dx: 1.5, dy: 1.5))
            focusPath.lineWidth = 2
            focusPath.stroke()
        }
    }

    private func pulse() {
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
        guard let layer = self.layer else { return }
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [1.0, 0.86, 1.0]
        animation.keyTimes = [0.0, 0.4, 1.0]
        animation.duration = 0.22
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        layer.add(animation, forKey: "pulse")
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        dragStartMouseLocation = window?.convertPoint(toScreen: event.locationInWindow)
        dragStartWindowOrigin = window?.frame.origin
        didDragWindow = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window = window,
              let startMouse = dragStartMouseLocation,
              let startOrigin = dragStartWindowOrigin else {
            return
        }

        let currentMouse = window.convertPoint(toScreen: event.locationInWindow)
        let deltaX = currentMouse.x - startMouse.x
        let deltaY = currentMouse.y - startMouse.y
        if !didDragWindow, hypot(deltaX, deltaY) < 3 {
            return
        }

        didDragWindow = true
        window.setFrameOrigin(NSPoint(
            x: startOrigin.x + deltaX,
            y: startOrigin.y + deltaY
        ))
    }

    override func mouseUp(with event: NSEvent) {
        let endMouse = window?.convertPoint(toScreen: event.locationInWindow)
        let totalDistance: CGFloat
        if let startMouse = dragStartMouseLocation, let endMouse = endMouse {
            totalDistance = hypot(endMouse.x - startMouse.x, endMouse.y - startMouse.y)
        } else {
            totalDistance = .greatestFiniteMagnitude
        }
        let shouldActivate = !didDragWindow
            && totalDistance < 3
            && bounds.contains(convert(event.locationInWindow, from: nil))
        dragStartMouseLocation = nil
        dragStartWindowOrigin = nil
        didDragWindow = false
        guard shouldActivate else { return }
        window?.makeFirstResponder(self)
        pulse()
        onClick?()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 || event.keyCode == 49 {
            pulse()
            onClick?()
        } else {
            super.keyDown(with: event)
        }
    }

    override func accessibilityPerformPress() -> Bool {
        pulse()
        onClick?()
        return true
    }
}
