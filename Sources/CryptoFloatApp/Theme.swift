import Cocoa

// MARK: - Themes
extension RGBColor {
    func color(alpha: CGFloat = 1) -> NSColor {
        return NSColor(
            calibratedRed: CGFloat(red / 255),
            green: CGFloat(green / 255),
            blue: CGFloat(blue / 255),
            alpha: alpha
        )
    }
}

func accessibilityAdjustedOpacity(_ requestedOpacity: CGFloat) -> CGFloat {
    return NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
        ? 1
        : min(max(requestedOpacity, 0), 1)
}

func accessibilityBackgroundAlpha(userOpacity: CGFloat) -> CGFloat {
    return NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
        ? 1
        : min(max(userOpacity, 0), 1)
}

extension NSView {
    func setAccessibilityValueAndNotify(_ value: String) {
        guard (accessibilityValue() as? String) != value else { return }
        setAccessibilityValue(value)
        NSAccessibility.post(element: self, notification: .valueChanged)
    }
}

extension AppTheme {
    var secondaryTextColor: NSColor {
        return foreground.color(alpha: CGFloat(AppTheme.secondaryTextAlpha))
    }

    var subduedTextColor: NSColor {
        return foreground.color(alpha: CGFloat(AppTheme.subduedTextAlpha))
    }

    var accentTextColor: NSColor {
        return accentText.color()
    }

    var negativeTextColor: NSColor {
        return negativeText.color()
    }
}
