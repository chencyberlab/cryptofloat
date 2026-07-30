import Cocoa

// MARK: - Glass Content View
class GlassContentView: NSView {
    private let cornerRadius: CGFloat = 22
    var backgroundOpacity: CGFloat = 0.85 {
        didSet { needsDisplay = true }
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        updateCornerMask()
    }

    override func layout() {
        super.layout()
        updateCornerMask()
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

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let fillPath = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)
        let theme = ThemeCatalog.current
        let opacity = accessibilityAdjustedOpacity(backgroundOpacity)
        theme.background.color(
            alpha: accessibilityBackgroundAlpha(userOpacity: backgroundOpacity)
        ).setFill()
        fillPath.fill()

        // Faint inner highlight along the top edge for a glassy sheen
        let highlight = NSBezierPath()
        highlight.move(to: NSPoint(x: cornerRadius, y: bounds.height - 1))
        highlight.line(to: NSPoint(x: bounds.width - cornerRadius, y: bounds.height - 1))
        theme.foreground.color(alpha: 0.12 * opacity).setStroke()
        highlight.lineWidth = 1
        highlight.stroke()

        let strokeRect = bounds.insetBy(dx: 0.75, dy: 0.75)
        let path = NSBezierPath(
            roundedRect: strokeRect,
            xRadius: max(cornerRadius - 0.75, 0),
            yRadius: max(cornerRadius - 0.75, 0)
        )
        theme.accent.color(alpha: 0.3 * opacity).setStroke()
        path.lineWidth = 1.5
        path.stroke()
    }
}
