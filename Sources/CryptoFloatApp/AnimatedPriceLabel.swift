import Cocoa

// MARK: - Animated Price Label
class AnimatedPriceLabel: NSTextField {
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
        layer?.masksToBounds = false
    }

    func flashGreen() {
        flash(color: ThemeCatalog.current.positive.color(alpha: 0.8))
    }

    func flashRed() {
        flash(color: ThemeCatalog.current.negative.color(alpha: 0.8))
    }

    private func flash(color: NSColor) {
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
        guard let layer = self.layer else { return }

        let flash = CALayer()
        flash.frame = layer.bounds.insetBy(dx: -4, dy: -2)
        flash.cornerRadius = 4
        flash.backgroundColor = color.cgColor
        flash.opacity = 0

        layer.insertSublayer(flash, at: 0)

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            flash.removeFromSuperlayer()
        }

        let animation = CAKeyframeAnimation(keyPath: "opacity")
        animation.values = [0.0, 0.7, 0.5, 0.0]
        animation.keyTimes = [0.0, 0.1, 0.5, 1.0]
        animation.duration = 0.6
        animation.isRemovedOnCompletion = true

        flash.add(animation, forKey: "flash")

        CATransaction.commit()
    }

    func animateValueChange(goingUp: Bool) {
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
        guard let layer = self.layer else { return }

        if goingUp {
            flashGreen()
        } else {
            flashRed()
        }

        let slideDistance: CGFloat = goingUp ? 3 : -3

        let slideAnimation = CAKeyframeAnimation(keyPath: "position.y")
        slideAnimation.values = [
            layer.position.y,
            layer.position.y + slideDistance,
            layer.position.y
        ]
        slideAnimation.keyTimes = [0.0, 0.3, 1.0]
        slideAnimation.duration = 0.3
        slideAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        layer.add(slideAnimation, forKey: "slide")

        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [1.0, 1.08, 1.0]
        scaleAnimation.keyTimes = [0.0, 0.2, 1.0]
        scaleAnimation.duration = 0.3
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        layer.add(scaleAnimation, forKey: "scale")
    }
}
