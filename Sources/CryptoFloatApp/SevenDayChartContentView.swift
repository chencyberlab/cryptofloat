import Cocoa

// MARK: - Seven Day Chart Popup
class SevenDayChartContentView: NSView {
    private let symbol: String
    private let quoteLabel: String
    private let cornerRadius: CGFloat = 22
    var backgroundOpacity: CGFloat = 0.85 {
        didSet { needsDisplay = true }
    }
    var onDismiss: (() -> Void)?

    private var points: [ChartPoint] = []
    private var isLoading = true
    private var hasError = false
    private var latestPrice: Double?
    private var change24h: Double?
    private var hoveredIndex: Int?
    private var trackingArea: NSTrackingArea?
    private lazy var closeButton: NSButton = {
        let button = NSButton(title: "×", target: self, action: #selector(dismissChart))
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: 18, weight: .medium)
        button.contentTintColor = ThemeCatalog.current.secondaryTextColor
        button.toolTip = "Close chart"
        button.setAccessibilityLabel("Close chart")
        button.setAccessibilityHelp("Closes the seven-day price chart.")
        return button
    }()

    private lazy var hoverDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d HH:mm"
        return f
    }()

    init(frame: NSRect, symbol: String, quoteLabel: String, latest: PriceData?) {
        self.symbol = symbol
        self.quoteLabel = quoteLabel
        if let latest = latest, !latest.hasError {
            self.latestPrice = latest.price
            self.change24h = latest.change24h
        }
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    private func setup() {
        wantsLayer = true
        setAccessibilityElement(true)
        setAccessibilityRole(.group)
        setAccessibilityLabel("\(symbol) seven-day price chart")
        setAccessibilityHelp("Move the pointer across the chart to inspect historical prices.")
        setupTrackingArea()
        addSubview(closeButton)
        layoutCloseButton()
    }

    override func layout() {
        super.layout()
        updateCornerMask()
        layoutCloseButton()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateCornerMask()
    }

    private func updateCornerMask() {
        guard let layer = layer else { return }
        layer.cornerRadius = cornerRadius
        if #available(macOS 10.15, *) {
            layer.cornerCurve = .continuous
        }
        layer.masksToBounds = true

        let mask = CAShapeLayer()
        mask.frame = bounds
        mask.path = CGPath(
            roundedRect: bounds,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
        layer.mask = mask
    }

    private func layoutCloseButton() {
        closeButton.frame = NSRect(
            x: bounds.width - 40,
            y: bounds.height - 40,
            width: 24,
            height: 24
        )
    }

    @objc private func dismissChart() {
        onDismiss?()
    }

    private func setupTrackingArea() {
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }

        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
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

    func setSummary(_ data: PriceData?) {
        guard let data = data, !data.hasError else { return }
        latestPrice = data.price
        change24h = data.change24h
        needsDisplay = true
    }

    func setPoints(_ points: [ChartPoint]) {
        self.points = points
        hoveredIndex = nil
        isLoading = false
        hasError = points.count < 2
        if let first = points.first, let last = points.last {
            let change = first.price > 0 ? ((last.price - first.price) / first.price) * 100 : 0
            setAccessibilityValueAndNotify(
                "\(PriceFormatter.shared.format(last.price)), "
                    + String(format: "%@%.2f percent over seven days", change >= 0 ? "plus " : "minus ", abs(change))
            )
        } else {
            setAccessibilityValueAndNotify("Chart unavailable")
        }
        needsDisplay = true
    }

    private func attributes(font: NSFont, color: NSColor, alignment: NSTextAlignment = .left) -> [NSAttributedString.Key: Any] {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        return [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: style
        ]
    }

    private func sevenDayChange() -> Double? {
        guard points.count >= 2,
              let first = points.first?.price,
              first != 0,
              let last = points.last?.price else {
            return nil
        }
        return ((last - first) / first) * 100
    }

    private func chartRect() -> NSRect {
        return NSRect(x: 18, y: 28, width: bounds.width - 36, height: 104)
    }

    private func updateHover(at location: NSPoint?) {
        guard points.count >= 2, let location = location, chartRect().contains(location) else {
            if hoveredIndex != nil {
                hoveredIndex = nil
                needsDisplay = true
            }
            return
        }

        let rect = chartRect()
        let clampedX = min(max(location.x, rect.minX), rect.maxX)
        let ratio = (clampedX - rect.minX) / rect.width
        let index = Int(round(ratio * CGFloat(points.count - 1)))
        let clampedIndex = min(max(index, 0), points.count - 1)

        if hoveredIndex != clampedIndex {
            hoveredIndex = clampedIndex
            needsDisplay = true
        }
    }

    override func mouseMoved(with event: NSEvent) {
        updateHover(at: convert(event.locationInWindow, from: nil))
    }

    override func mouseExited(with event: NSEvent) {
        updateHover(at: nil)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onDismiss?()
            return
        }
        guard !points.isEmpty, event.keyCode == 123 || event.keyCode == 124 else {
            super.keyDown(with: event)
            return
        }

        if let current = hoveredIndex {
            hoveredIndex = event.keyCode == 123
                ? max(current - 1, 0)
                : min(current + 1, points.count - 1)
        } else {
            hoveredIndex = event.keyCode == 123 ? points.count - 1 : 0
        }

        if let hoveredIndex = hoveredIndex {
            let point = points[hoveredIndex]
            setAccessibilityValueAndNotify(
                "\(hoverDateFormatter.string(from: Date(timeIntervalSince1970: point.time))), "
                    + PriceFormatter.shared.format(point.price)
            )
        }
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let fillPath = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)
        let theme = ThemeCatalog.current
        let opacity = accessibilityAdjustedOpacity(backgroundOpacity)
        theme.backgroundDark.color(
            alpha: accessibilityBackgroundAlpha(userOpacity: backgroundOpacity)
        ).setFill()
        fillPath.fill()

        let strokeRect = bounds.insetBy(dx: 0.75, dy: 0.75)
        let strokePath = NSBezierPath(
            roundedRect: strokeRect,
            xRadius: max(cornerRadius - 0.75, 0),
            yRadius: max(cornerRadius - 0.75, 0)
        )
        theme.accent.color(alpha: 0.36 * opacity).setStroke()
        strokePath.lineWidth = 1.5
        strokePath.stroke()

        let titleAttrs = attributes(
            font: NSFont.systemFont(ofSize: 14, weight: .semibold),
            color: theme.foreground.color()
        )
        (titleAttrs[.paragraphStyle] as? NSMutableParagraphStyle)?.lineBreakMode = .byTruncatingMiddle
        "\(symbol)/\(quoteLabel)".draw(
            in: NSRect(
                x: 18,
                y: bounds.height - 34,
                width: max(bounds.width - 116, 40),
                height: 18
            ),
            withAttributes: titleAttrs
        )

        let tagAttrs = attributes(
            font: NSFont.systemFont(ofSize: 10, weight: .semibold),
            color: theme.accentTextColor,
            alignment: .right
        )
        "7D".draw(
            in: NSRect(x: bounds.width - 84, y: bounds.height - 31, width: 36, height: 14),
            withAttributes: tagAttrs
        )

        let hoveredPoint = hoveredIndex.flatMap { points.indices.contains($0) ? points[$0] : nil }
        let displayPrice = hoveredPoint?.price ?? latestPrice

        if let displayPrice = displayPrice {
            let priceAttrs = attributes(
                font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
                color: theme.foreground.color(alpha: 0.82)
            )
            PriceFormatter.shared.format(displayPrice).draw(
                at: NSPoint(x: 18, y: bounds.height - 54),
                withAttributes: priceAttrs
            )
        }

        if let hoveredPoint = hoveredPoint {
            let dateAttrs = attributes(
                font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular),
                color: theme.accentTextColor,
                alignment: .right
            )
            hoverDateFormatter.string(from: Date(timeIntervalSince1970: hoveredPoint.time)).draw(
                in: NSRect(x: bounds.width - 122, y: bounds.height - 54, width: 104, height: 14),
                withAttributes: dateAttrs
            )
        } else if let change = sevenDayChange() ?? change24h {
            let isUp = change >= 0
            let color = isUp
                ? theme.positive.color(alpha: 0.95)
                : theme.negativeTextColor
            let changeAttrs = attributes(
                font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
                color: color,
                alignment: .right
            )
            let text = String(format: "%@%.2f%%", isUp ? "+" : "", change)
            text.draw(in: NSRect(x: bounds.width - 100, y: bounds.height - 54, width: 82, height: 16), withAttributes: changeAttrs)
        }

        drawChart(in: chartRect())
    }

    private func drawChart(in rect: NSRect) {
        let theme = ThemeCatalog.current
        let gridColor = theme.foreground.color(alpha: 0.08)
        for i in 0...3 {
            let y = rect.minY + rect.height * CGFloat(i) / 3.0
            let line = NSBezierPath()
            line.move(to: NSPoint(x: rect.minX, y: y))
            line.line(to: NSPoint(x: rect.maxX, y: y))
            gridColor.setStroke()
            line.lineWidth = 0.6
            line.stroke()
        }

        guard points.count >= 2, !hasError else {
            let text = isLoading ? "Loading chart..." : "Chart unavailable"
            let attrs = attributes(
                font: NSFont.systemFont(ofSize: 12, weight: .regular),
                color: theme.secondaryTextColor,
                alignment: .center
            )
            text.draw(in: NSRect(x: rect.minX, y: rect.midY - 8, width: rect.width, height: 18), withAttributes: attrs)
            return
        }

        let values = points.map { $0.price }
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 0
        let range = max(maxV - minV, 0.00000001)
        let inset: CGFloat = 7
        let stepX = rect.width / CGFloat(values.count - 1)

        func point(_ i: Int) -> NSPoint {
            let x = rect.minX + CGFloat(i) * stepX
            let norm = CGFloat((values[i] - minV) / range)
            let y = rect.minY + inset + norm * (rect.height - 2 * inset)
            return NSPoint(x: x, y: y)
        }

        let isUp = (values.last ?? 0) >= (values.first ?? 0)
        let lineColor = isUp
            ? theme.positive.color(alpha: 0.98)
            : theme.negative.color(alpha: 0.98)

        let fillPath = NSBezierPath()
        fillPath.move(to: NSPoint(x: rect.minX, y: rect.minY))
        for i in 0..<values.count {
            fillPath.line(to: point(i))
        }
        fillPath.line(to: NSPoint(x: rect.maxX, y: rect.minY))
        fillPath.close()
        if let gradient = NSGradient(
            starting: lineColor.withAlphaComponent(0.02),
            ending: lineColor.withAlphaComponent(0.26)
        ) {
            gradient.draw(in: fillPath, angle: 90)
        }

        let linePath = NSBezierPath()
        linePath.lineJoinStyle = .round
        linePath.lineCapStyle = .round
        for i in 0..<values.count {
            if i == 0 {
                linePath.move(to: point(i))
            } else {
                linePath.line(to: point(i))
            }
        }
        lineColor.setStroke()
        linePath.lineWidth = 2
        linePath.stroke()

        let last = point(values.count - 1)
        let dot = NSBezierPath(ovalIn: NSRect(x: last.x - 3, y: last.y - 3, width: 6, height: 6))
        lineColor.setFill()
        dot.fill()

        if let hoveredIndex = hoveredIndex, values.indices.contains(hoveredIndex) {
            let hovered = point(hoveredIndex)

            let guide = NSBezierPath()
            guide.move(to: NSPoint(x: hovered.x, y: rect.minY))
            guide.line(to: NSPoint(x: hovered.x, y: rect.maxY))
            theme.foreground.color(alpha: 0.22).setStroke()
            guide.lineWidth = 1
            guide.stroke()

            let ring = NSBezierPath(ovalIn: NSRect(x: hovered.x - 4, y: hovered.y - 4, width: 8, height: 8))
            theme.backgroundDark.color(alpha: 0.96).setFill()
            ring.fill()
            lineColor.setStroke()
            ring.lineWidth = 2
            ring.stroke()

            let tooltip = PriceFormatter.shared.format(values[hoveredIndex])
            let tooltipAttrs = attributes(
                font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium),
                color: theme.foreground.color(),
                alignment: .center
            )
            let textSize = tooltip.size(withAttributes: tooltipAttrs)
            let tooltipWidth = min(max(textSize.width + 14, 72), rect.width)
            let tooltipX = min(max(hovered.x - tooltipWidth / 2, rect.minX), rect.maxX - tooltipWidth)
            let tooltipY = min(hovered.y + 12, rect.maxY - 22)
            let tooltipRect = NSRect(x: tooltipX, y: tooltipY, width: tooltipWidth, height: 20)
            let tooltipPath = NSBezierPath(roundedRect: tooltipRect, xRadius: 7, yRadius: 7)
            theme.backgroundDark.color(alpha: 0.9).setFill()
            tooltipPath.fill()
            theme.foreground.color(alpha: 0.16).setStroke()
            tooltipPath.lineWidth = 1
            tooltipPath.stroke()
            tooltip.draw(in: tooltipRect.insetBy(dx: 4, dy: 3), withAttributes: tooltipAttrs)
        }

        let rangeAttrs = attributes(
            font: NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .regular),
            color: theme.secondaryTextColor,
            alignment: .right
        )
        PriceFormatter.shared.compact(maxV).draw(
            in: NSRect(x: rect.maxX - 76, y: rect.maxY - 14, width: 76, height: 12),
            withAttributes: rangeAttrs
        )
        PriceFormatter.shared.compact(minV).draw(
            in: NSRect(x: rect.maxX - 76, y: rect.minY + 2, width: 76, height: 12),
            withAttributes: rangeAttrs
        )
    }
}
