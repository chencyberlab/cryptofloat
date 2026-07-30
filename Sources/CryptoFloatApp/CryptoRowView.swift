import Cocoa

// MARK: - Crypto Row View
class CryptoRowView: NSButton {
    let symbol: String
    let showSparkline: Bool
    var onClick: ((CryptoRowView) -> Void)?

    private let symbolLabel = NSTextField(labelWithString: "")
    private let priceLabel = AnimatedPriceLabel(labelWithString: "Loading…")
    private let changeLabel = NSTextField(labelWithString: "")
    private let arrowLabel = NSTextField(labelWithString: "")
    private var sparklineView: SparklineView?

    private var lastPrice: Double = 0
    private var hasLoaded = false
    private var isHovered = false

    private var dimColor: NSColor {
        ThemeCatalog.current.secondaryTextColor
    }

    private func displayPrice(_ price: Double) -> String {
        return showSparkline
            ? PriceFormatter.shared.format(price)
            : PriceFormatter.shared.compact(price)
    }

    init(frame: NSRect, symbol: String, showSparkline: Bool) {
        self.symbol = symbol
        self.showSparkline = showSparkline
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func makeLabel(_ field: NSTextField) {
        field.isBezeled = false
        field.drawsBackground = false
        field.isEditable = false
        field.isSelectable = false
        field.setAccessibilityElement(false)
        field.setAccessibilityHidden(true)
    }

    private func setup() {
        wantsLayer = true
        let w = bounds.width

        title = ""
        isBordered = false
        setButtonType(.momentaryChange)
        target = self
        action = #selector(handleButtonPress)

        toolTip = "Show \(symbol) seven-day chart"
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel("\(symbol) price")
        setAccessibilityHelp("Shows the seven-day price chart for \(symbol).")

        makeLabel(symbolLabel)
        makeLabel(priceLabel)
        makeLabel(changeLabel)
        makeLabel(arrowLabel)

        symbolLabel.stringValue = symbol
        symbolLabel.lineBreakMode = .byTruncatingMiddle
        symbolLabel.textColor = ThemeCatalog.current.foreground.color()
        addSubview(symbolLabel)

        priceLabel.textColor = ThemeCatalog.current.foreground.color()
        priceLabel.alignment = .left
        addSubview(priceLabel)

        changeLabel.alignment = .right
        addSubview(changeLabel)

        arrowLabel.alignment = .center
        arrowLabel.wantsLayer = true

        if showSparkline {
            // Two-line layout: symbol + 24h% on top, price + arrow + sparkline below.
            symbolLabel.font = NSFont.boldSystemFont(ofSize: 14)
            symbolLabel.frame = NSRect(x: 14, y: 26, width: 90, height: 18)

            changeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
            changeLabel.frame = NSRect(x: w - 84, y: 27, width: 72, height: 16)

            priceLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
            priceLabel.frame = NSRect(x: 14, y: 6, width: 104, height: 18)

            arrowLabel.font = NSFont.systemFont(ofSize: 10, weight: .bold)
            arrowLabel.frame = NSRect(x: 118, y: 7, width: 14, height: 16)
            addSubview(arrowLabel)

            let spark = SparklineView(frame: NSRect(x: 140, y: 5, width: w - 152, height: 19))
            spark.setAccessibilityElement(false)
            spark.setAccessibilityHidden(true)
            addSubview(spark)
            sparklineView = spark
        } else {
            // Compact single-line layout.
            symbolLabel.font = NSFont.boldSystemFont(ofSize: 14)
            symbolLabel.frame = NSRect(x: 14, y: 5, width: 56, height: 20)

            priceLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            priceLabel.frame = NSRect(x: 74, y: 5, width: max(w - 162, 72), height: 20)

            changeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
            changeLabel.frame = NSRect(x: w - 76, y: 6, width: 64, height: 18)
        }

        let tracking = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(tracking)

    }

    override var acceptsFirstResponder: Bool { true }
    override var mouseDownCanMoveWindow: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func accessibilityChildren() -> [Any]? { [] }

    override func hitTest(_ point: NSPoint) -> NSView? {
        return bounds.contains(point) && !isHidden && alphaValue > 0 ? self : nil
    }

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

    func setSparkline(_ values: [Double]) {
        sparklineView?.setValues(values)
    }

    func update(price: Double, change: Double?, hasError: Bool) {
        if hasError {
            if price > 0 {
                priceLabel.stringValue = displayPrice(price)
                if let change = change {
                    changeLabel.stringValue = String(
                        format: "%@%.2f%%",
                        change >= 0 ? "+" : "",
                        change
                    )
                } else {
                    changeLabel.stringValue = "—"
                }
                lastPrice = price
                hasLoaded = true
                priceLabel.textColor = dimColor
                changeLabel.textColor = dimColor
                arrowLabel.stringValue = ""
            } else if hasLoaded {
                // Keep the last known price, just dim it to signal staleness.
                priceLabel.textColor = dimColor
                changeLabel.textColor = dimColor
                arrowLabel.stringValue = ""
            } else {
                priceLabel.stringValue = "—"
                priceLabel.textColor = dimColor
                changeLabel.stringValue = ""
                arrowLabel.stringValue = ""
            }
            let staleValue = hasLoaded ? "\(priceLabel.stringValue), temporarily unavailable" : "Price unavailable"
            setAccessibilityValueAndNotify(staleValue)
            return
        }

        let priceWentUp = hasLoaded && price > lastPrice
        let priceWentDown = hasLoaded && price < lastPrice
        let priceChanged = hasLoaded && price != lastPrice

        priceLabel.stringValue = displayPrice(price)
        priceLabel.textColor = ThemeCatalog.current.foreground.color()

        if priceChanged {
            if priceWentUp {
                arrowLabel.stringValue = "▲"
                arrowLabel.textColor = ThemeCatalog.current.positive.color()
                priceLabel.animateValueChange(goingUp: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.fadeOutArrow()
                }
            } else if priceWentDown {
                arrowLabel.stringValue = "▼"
                arrowLabel.textColor = ThemeCatalog.current.negative.color()
                priceLabel.animateValueChange(goingUp: false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.fadeOutArrow()
                }
            }
        }

        if let change = change, change >= 0 {
            changeLabel.stringValue = String(format: "+%.2f%%", change)
            changeLabel.textColor = ThemeCatalog.current.positive.color()
        } else if let change = change {
            changeLabel.stringValue = String(format: "%.2f%%", change)
            changeLabel.textColor = ThemeCatalog.current.negativeTextColor
        } else {
            changeLabel.stringValue = "—"
            changeLabel.textColor = dimColor
        }

        lastPrice = price
        hasLoaded = true
        if let change = change {
            setAccessibilityValueAndNotify(
                "\(PriceFormatter.shared.format(price)), "
                    + String(format: "%@%.2f percent over 24 hours", change >= 0 ? "plus " : "minus ", abs(change))
            )
        } else {
            setAccessibilityValueAndNotify("\(PriceFormatter.shared.format(price)), 24-hour change unavailable")
        }
    }

    private func fadeOutArrow() {
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
            arrowLabel.stringValue = ""
            arrowLabel.alphaValue = 1
            return
        }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            arrowLabel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.arrowLabel.stringValue = ""
            self?.arrowLabel.alphaValue = 1
        })
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 36 || event.keyCode == 49 {
            onClick?(self)
        } else {
            super.keyDown(with: event)
        }
    }

    override func accessibilityPerformPress() -> Bool {
        onClick?(self)
        return true
    }

    @objc private func handleButtonPress() {
        window?.makeFirstResponder(self)
        onClick?(self)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if isHovered {
            let bg = NSBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 3), xRadius: 8, yRadius: 8)
            ThemeCatalog.current.foreground.color(alpha: 0.06).setFill()
            bg.fill()
        }

        let separator = NSBezierPath()
        separator.move(to: NSPoint(x: 12, y: 0.5))
        separator.line(to: NSPoint(x: bounds.width - 12, y: 0.5))
        ThemeCatalog.current.foreground.color(alpha: 0.07).setStroke()
        separator.lineWidth = 0.5
        separator.stroke()

        if window?.firstResponder === self {
            NSColor.keyboardFocusIndicatorColor.setStroke()
            let focusPath = NSBezierPath(
                roundedRect: bounds.insetBy(dx: 4, dy: 3),
                xRadius: 8,
                yRadius: 8
            )
            focusPath.lineWidth = 2
            focusPath.stroke()
        }
    }
}
