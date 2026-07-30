import CoreGraphics
import Foundation

enum FloatingWidgetLayout {
    static func frame(
        mode: FloatingWidgetMode,
        isExpanded: Bool,
        containerSize: NSSize,
        widgetWidth: CGFloat,
        widgetHeight: CGFloat,
        inset: CGFloat = 5
    ) -> NSRect {
        let y: CGFloat
        if mode == .marquee, isExpanded {
            y = max(containerSize.height - widgetHeight - inset, inset)
        } else {
            y = inset
        }

        return NSRect(
            x: inset,
            y: y,
            width: widgetWidth,
            height: widgetHeight
        )
    }

    static func windowOrigin(
        preservingWidgetAt screenOrigin: NSPoint,
        targetWidgetFrame: NSRect
    ) -> NSPoint {
        return NSPoint(
            x: screenOrigin.x - targetWidgetFrame.minX,
            y: screenOrigin.y - targetWidgetFrame.minY
        )
    }
}
