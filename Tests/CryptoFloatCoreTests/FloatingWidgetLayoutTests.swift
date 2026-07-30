import CoreGraphics
import Foundation
import XCTest
@testable import CryptoFloatCore

final class FloatingWidgetLayoutTests: XCTestCase {
    func testBitcoinWidgetStaysBottomAnchoredAtEverySize() {
        for expanded in [false, true] {
            let frame = FloatingWidgetLayout.frame(
                mode: .bitcoin,
                isExpanded: expanded,
                containerSize: NSSize(width: 340, height: expanded ? 480 : 54),
                widgetWidth: 44,
                widgetHeight: 44
            )
            XCTAssertEqual(frame.origin, NSPoint(x: 5, y: 5))
        }
    }

    func testExpandedMarqueeStaysAtTopInset() {
        let frame = FloatingWidgetLayout.frame(
            mode: .marquee,
            isExpanded: true,
            containerSize: NSSize(width: 284, height: 480),
            widgetWidth: 274,
            widgetHeight: 44
        )
        XCTAssertEqual(frame.origin, NSPoint(x: 5, y: 431))
    }

    func testCollapsedMarqueeStaysAtBottomInset() {
        let frame = FloatingWidgetLayout.frame(
            mode: .marquee,
            isExpanded: false,
            containerSize: NSSize(width: 284, height: 54),
            widgetWidth: 274,
            widgetHeight: 44
        )
        XCTAssertEqual(frame.origin, NSPoint(x: 5, y: 5))
    }

    func testWindowOriginPreservesWidgetScreenPosition() {
        let origin = FloatingWidgetLayout.windowOrigin(
            preservingWidgetAt: NSPoint(x: 850, y: 700),
            targetWidgetFrame: NSRect(x: 5, y: 431, width: 274, height: 44)
        )
        XCTAssertEqual(origin, NSPoint(x: 845, y: 269))
    }
}
