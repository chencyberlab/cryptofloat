import Cocoa

// MARK: - Sparkline View
class SparklineView: NSView {
    private var values: [Double] = []

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    func setValues(_ values: [Double]) {
        self.values = values
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard values.count >= 2, bounds.width > 1, bounds.height > 1 else { return }

        let minV = values.min() ?? 0
        let maxV = values.max() ?? 0
        let range = maxV - minV
        let inset: CGFloat = 3
        let stepX = bounds.width / CGFloat(values.count - 1)

        func point(_ i: Int) -> NSPoint {
            let x = CGFloat(i) * stepX
            let norm: CGFloat = range > 0 ? CGFloat((values[i] - minV) / range) : 0.5
            let y = inset + norm * (bounds.height - 2 * inset)
            return NSPoint(x: x, y: y)
        }

        let isUp = (values.last ?? 0) >= (values.first ?? 0)
        let lineColor = isUp
            ? ThemeCatalog.current.positive.color(alpha: 0.95)
            : ThemeCatalog.current.negative.color(alpha: 0.95)

        // Gradient fill beneath the line
        let fillPath = NSBezierPath()
        fillPath.move(to: NSPoint(x: 0, y: 0))
        for i in 0..<values.count {
            fillPath.line(to: point(i))
        }
        fillPath.line(to: NSPoint(x: bounds.width, y: 0))
        fillPath.close()
        if let gradient = NSGradient(starting: lineColor.withAlphaComponent(0.0),
                                     ending: lineColor.withAlphaComponent(0.28)) {
            gradient.draw(in: fillPath, angle: 90)
        }

        // The trend line itself
        let linePath = NSBezierPath()
        linePath.lineJoinStyle = .round
        linePath.lineCapStyle = .round
        for i in 0..<values.count {
            if i == 0 { linePath.move(to: point(i)) } else { linePath.line(to: point(i)) }
        }
        lineColor.setStroke()
        linePath.lineWidth = 1.6
        linePath.stroke()

        // End dot to anchor the eye on the latest value
        let last = point(values.count - 1)
        let dot = NSBezierPath(ovalIn: NSRect(x: last.x - 2, y: last.y - 2, width: 4, height: 4))
        lineColor.setFill()
        dot.fill()
    }
}
