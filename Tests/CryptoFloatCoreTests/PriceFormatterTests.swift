import Foundation
import XCTest
@testable import CryptoFloatCore

final class PriceFormatterTests: XCTestCase {
    private var formatter: PriceFormatter!

    override func setUp() {
        super.setUp()
        formatter = PriceFormatter(locale: Locale(identifier: "en_US"))
    }

    override func tearDown() {
        formatter = nil
        super.tearDown()
    }

    func testFormatsRegularSmallAndVerySmallPrices() {
        XCTAssertEqual(formatter.format(1_234.5), "$1,234.50")
        XCTAssertEqual(formatter.format(0.00123456), "$0.001235")
        XCTAssertEqual(formatter.format(0.00009999), "$0.00009999")
    }

    func testRejectsNegativeAndNonFinitePrices() {
        XCTAssertEqual(formatter.format(-1), "—")
        XCTAssertEqual(formatter.format(.nan), "—")
        XCTAssertEqual(formatter.format(.infinity), "—")
        XCTAssertEqual(formatter.compact(-1), "—")
        XCTAssertEqual(formatter.compact(.nan), "—")
    }

    func testNormalizesNegativeZero() {
        XCTAssertEqual(formatter.format(-0.0), formatter.format(0))
        XCTAssertFalse(formatter.format(-0.0).contains("-"))
        XCTAssertFalse(formatter.compact(-0.0).contains("-"))
    }

    func testCompactFormattingUsesRoundedGroupedThousands() {
        XCTAssertEqual(formatter.compact(1_234.6), "$1,235")
        XCTAssertEqual(formatter.compact(1_000), "$1,000")
        XCTAssertEqual(formatter.compact(999.999), "$1,000")
        XCTAssertEqual(formatter.compact(12.346), "$12.35")
    }

    func testCompactFormattingDelegatesSmallPricesToFullFormatter() {
        XCTAssertEqual(formatter.compact(0.0012), formatter.format(0.0012))
    }
}
