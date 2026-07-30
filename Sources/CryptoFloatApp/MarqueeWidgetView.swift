import Cocoa

// MARK: - Marquee Widget View
class MarqueeWidgetView: NSView {
    var onClick: (() -> Void)?
    var isExpanded = true {
        didSet { updateAccessibilityValue() }
    }
    var backgroundOpacity: CGFloat = 0.85 {
        didSet { needsDisplay = true }
    }
    var accentChange: Double = 0 {
        didSet { needsDisplay = true }
    }

    private var symbols: [String] = []
    private var prices: [String: PriceData] = [:]
    private var isHovered = false
    private var scrollOffset: CGFloat = 0
    private var scrollTimer: Timer?
    private var isPaused = false
    private var trackingArea: NSTrackingArea?
    private var accessibilitySummary = "Prices loading"
    private var dragStartMouseLocation: NSPoint?
    private var dragStartWindowOrigin: NSPoint?
    private var didDragWindow = false

    private let sidePadding: CGFloat = 14
    private let itemGap: CGFloat = 28

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit {
        scrollTimer?.invalidate()
    }

    private func setup() {
        wantsLayer = true
        setupTrackingArea()
        startScrolling()
        toolTip = "Expand or collapse cryptocurrency prices"
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel("Scrolling cryptocurrency prices")
        setAccessibilityHelp("Expands or collapses the cryptocurrency price panel.")
    }

    override var mouseDownCanMoveWindow: Bool { false }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func accessibilityChildren() -> [Any]? { [] }

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

    private func setupTrackingArea() {
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }

        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        trackingArea = area
        addTrackingArea(area)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        setupTrackingArea()
    }

    func setMarketData(symbols: [String], prices: [String: PriceData]) {
        self.symbols = symbols
        self.prices = prices
        let summary = symbols.compactMap { symbol -> String? in
            guard let data = prices[symbol], data.price > 0 else { return nil }
            return "\(symbol) \(PriceFormatter.shared.compact(data.price))"
        }.joined(separator: ", ")
        let fallback = symbols.isEmpty ? "No tracked assets" : "Prices loading"
        accessibilitySummary = summary.isEmpty ? fallback : summary
        updateAccessibilityValue()
        needsDisplay = true
    }

    private func updateAccessibilityValue() {
        setAccessibilityValueAndNotify(
            "\(isExpanded ? "Expanded" : "Collapsed"). \(accessibilitySummary)"
        )
    }

    func setPaused(_ paused: Bool) {
        isPaused = paused
        if paused {
            scrollTimer?.invalidate()
            scrollTimer = nil
        } else if scrollTimer == nil {
            startScrolling()
        }
    }

    private func startScrolling() {
        scrollTimer?.invalidate()

        let timer = Timer(timeInterval: 1.0 / 20.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            guard !self.isPaused,
                  self.window?.isVisible == true,
                  !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
                if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion,
                   self.scrollOffset != 0 {
                    self.scrollOffset = 0
                    self.needsDisplay = true
                }
                return
            }
            self.scrollOffset += self.isHovered ? 0.5 : 1.1
            let cycle = max(self.marqueeWidth(), 1)
            if self.scrollOffset > cycle {
                self.scrollOffset -= cycle
            }
            self.needsDisplay = true
        }
        scrollTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func accentColor(alpha: CGFloat = 1) -> NSColor {
        let theme = ThemeCatalog.current
        if accentChange > 0.05 {
            return theme.positive.color(alpha: alpha)
        } else if accentChange < -0.05 {
            return theme.negative.color(alpha: alpha)
        }
        return theme.accent.color(alpha: alpha)
    }

    private func attributes(font: NSFont, color: NSColor) -> [NSAttributedString.Key: Any] {
        return [
            .font: font,
            .foregroundColor: color
        ]
    }

    private var symbolAttrs: [NSAttributedString.Key: Any] {
        attributes(font: NSFont.systemFont(ofSize: 13, weight: .bold), color: ThemeCatalog.current.foreground.color())
    }

    private var priceAttrs: [NSAttributedString.Key: Any] {
        attributes(
            font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
            color: ThemeCatalog.current.foreground.color(alpha: 0.86)
        )
    }

    private var loadingAttrs: [NSAttributedString.Key: Any] {
        attributes(
            font: NSFont.systemFont(ofSize: 12, weight: .medium),
            color: ThemeCatalog.current.secondaryTextColor
        )
    }

    private var staleAttrs: [NSAttributedString.Key: Any] {
        attributes(
            font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
            color: ThemeCatalog.current.secondaryTextColor
        )
    }

    private func changeAttrs(for change: Double) -> [NSAttributedString.Key: Any] {
        let color = change >= 0
            ? ThemeCatalog.current.positive.color()
            : ThemeCatalog.current.negativeTextColor
        return attributes(font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium), color: color)
    }

    private func measuredTextWidth(_ text: String, attrs: [NSAttributedString.Key: Any]) -> CGFloat {
        return ceil(text.size(withAttributes: attrs).width)
    }

    private func placeholderText(for symbol: String) -> String {
        return prices[symbol]?.hasError == true ? "Unavailable" : "Loading"
    }

    private func itemWidth(for symbol: String) -> CGFloat {
        guard let data = prices[symbol], data.price > 0 else {
            let placeholder = placeholderText(for: symbol)
            return measuredTextWidth(symbol, attrs: symbolAttrs)
                + 6
                + measuredTextWidth(placeholder, attrs: loadingAttrs)
        }

        let priceText = PriceFormatter.shared.compact(data.price)
        let changeText = data.change24h.map {
            String(format: "%@%.2f%%", $0 >= 0 ? "+" : "", $0)
        } ?? "—"
        let valueAttrs = data.hasError ? staleAttrs : priceAttrs
        let movementAttrs = data.hasError || data.change24h == nil
            ? staleAttrs
            : changeAttrs(for: data.change24h!)
        return measuredTextWidth(symbol, attrs: symbolAttrs)
            + 8
            + measuredTextWidth(priceText, attrs: valueAttrs)
            + 8
            + measuredTextWidth(changeText, attrs: movementAttrs)
    }

    private func marqueeWidth() -> CGFloat {
        if symbols.isEmpty {
            return max(
                measuredTextWidth("No assets · Add from menu", attrs: loadingAttrs) + itemGap,
                bounds.width - sidePadding * 2
            )
        }
        let activeSymbols = symbols
        let width = activeSymbols.reduce(CGFloat(0)) { partial, symbol in
            partial + itemWidth(for: symbol) + itemGap
        }
        return max(width, bounds.width - sidePadding * 2)
    }

    private func drawItems(startingAt startX: CGFloat, baselineY: CGFloat) {
        guard !symbols.isEmpty else {
            "No assets · Add from menu".draw(
                at: NSPoint(x: startX, y: baselineY),
                withAttributes: loadingAttrs
            )
            return
        }
        let activeSymbols = symbols
        var x = startX

        for symbol in activeSymbols {
            symbol.draw(at: NSPoint(x: x, y: baselineY), withAttributes: symbolAttrs)
            x += measuredTextWidth(symbol, attrs: symbolAttrs) + 8

            if let data = prices[symbol], data.price > 0 {
                let priceText = PriceFormatter.shared.compact(data.price)
                let valueAttrs = data.hasError ? staleAttrs : priceAttrs
                let movementAttrs = data.hasError || data.change24h == nil
                    ? staleAttrs
                    : changeAttrs(for: data.change24h!)
                priceText.draw(at: NSPoint(x: x, y: baselineY), withAttributes: valueAttrs)
                x += measuredTextWidth(priceText, attrs: valueAttrs) + 8

                let changeText = data.change24h.map {
                    String(format: "%@%.2f%%", $0 >= 0 ? "+" : "", $0)
                } ?? "—"
                changeText.draw(at: NSPoint(x: x, y: baselineY), withAttributes: movementAttrs)
                x += measuredTextWidth(changeText, attrs: movementAttrs)
            } else {
                let placeholder = placeholderText(for: symbol)
                placeholder.draw(at: NSPoint(x: x, y: baselineY), withAttributes: loadingAttrs)
                x += measuredTextWidth(placeholder, attrs: loadingAttrs)
            }

            let dotAttrs = attributes(
                font: NSFont.systemFont(ofSize: 10, weight: .semibold),
                color: ThemeCatalog.current.foreground.color(alpha: 0.25)
            )
            let dotX = x + itemGap / 2 - 2
            "•".draw(at: NSPoint(x: dotX, y: baselineY + 1), withAttributes: dotAttrs)
            x += itemGap
        }
    }

    private func pulse() {
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
        guard let layer = self.layer else { return }
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [1.0, 0.97, 1.0]
        animation.keyTimes = [0.0, 0.4, 1.0]
        animation.duration = 0.18
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

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let rect = bounds.insetBy(dx: 2, dy: 3)
        let background = NSBezierPath(roundedRect: rect, xRadius: rect.height / 2, yRadius: rect.height / 2)
        let theme = ThemeCatalog.current
        let opacity = accessibilityAdjustedOpacity(backgroundOpacity)

        let top: NSColor
        let bottom: NSColor
        if NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency {
            top = theme.background.color()
            bottom = theme.backgroundDark.color()
        } else {
            top = isHovered
                ? (
                    theme.background.color().blended(
                        withFraction: 0.22,
                        of: theme.accent.color()
                    ) ?? theme.background.color()
                ).withAlphaComponent(opacity)
                : theme.background.color(alpha: opacity)
            bottom = isHovered
                ? theme.background.color(alpha: opacity)
                : theme.backgroundDark.color(alpha: opacity)
        }

        if let gradient = NSGradient(starting: top, ending: bottom) {
            gradient.draw(in: background, angle: -90)
        } else {
            bottom.setFill()
            background.fill()
        }

        accentColor(alpha: (isHovered ? 0.30 : 0.18) * opacity).setStroke()
        background.lineWidth = 1
        background.stroke()

        NSGraphicsContext.saveGraphicsState()
        background.addClip()

        let baselineY = (bounds.height - 15) / 2
        let cycle = marqueeWidth()
        let startX = sidePadding - scrollOffset
        drawItems(startingAt: startX, baselineY: baselineY)
        drawItems(startingAt: startX + cycle, baselineY: baselineY)
        if startX + cycle < bounds.width {
            drawItems(startingAt: startX + cycle * 2, baselineY: baselineY)
        }

        let leftFade = NSBezierPath(rect: NSRect(x: rect.minX, y: rect.minY + 2, width: 22, height: rect.height - 4))
        if let gradient = NSGradient(
            starting: theme.background.color(alpha: 0.72 * opacity),
            ending: theme.background.color(alpha: 0)
        ) {
            gradient.draw(in: leftFade, angle: 0)
        }

        let rightFade = NSBezierPath(rect: NSRect(x: rect.maxX - 22, y: rect.minY + 2, width: 22, height: rect.height - 4))
        if let gradient = NSGradient(
            starting: theme.background.color(alpha: 0),
            ending: theme.background.color(alpha: 0.72 * opacity)
        ) {
            gradient.draw(in: rightFade, angle: 0)
        }

        NSGraphicsContext.restoreGraphicsState()

        if window?.firstResponder === self {
            NSColor.keyboardFocusIndicatorColor.setStroke()
            let focusPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 1.5, dy: 2.5), xRadius: bounds.height / 2, yRadius: bounds.height / 2)
            focusPath.lineWidth = 2
            focusPath.stroke()
        }
    }
}
