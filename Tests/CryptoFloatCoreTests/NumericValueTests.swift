import Foundation
import XCTest
@testable import CryptoFloatCore

final class NumericValueTests: XCTestCase {
    func testFiniteDoubleAcceptsNumbersAndNumericStrings() {
        XCTAssertEqual(NumericValue.finiteDouble(from: NSNumber(value: 12.5)), 12.5)
        XCTAssertEqual(NumericValue.finiteDouble(from: "12.5"), 12.5)
        XCTAssertEqual(NumericValue.finiteDouble(from: "-2"), -2)
        XCTAssertEqual(NumericValue.finiteDouble(from: 0), 0)
    }

    func testFiniteDoubleRejectsBooleansAndNonFiniteValues() {
        XCTAssertNil(NumericValue.finiteDouble(from: true))
        XCTAssertNil(NumericValue.finiteDouble(from: NSNumber(value: false)))
        XCTAssertNil(NumericValue.finiteDouble(from: "NaN"))
        XCTAssertNil(NumericValue.finiteDouble(from: "infinity"))
        XCTAssertNil(NumericValue.finiteDouble(from: Double.infinity))
        XCTAssertNil(NumericValue.finiteDouble(from: Double.nan))
        XCTAssertNil(NumericValue.finiteDouble(from: "not-a-number"))
        XCTAssertNil(NumericValue.finiteDouble(from: nil))
    }

    func testPositiveDoubleRequiresStrictlyPositiveFiniteValue() {
        XCTAssertEqual(NumericValue.positiveDouble(from: "0.0001"), 0.0001)
        XCTAssertNil(NumericValue.positiveDouble(from: 0))
        XCTAssertNil(NumericValue.positiveDouble(from: -1))
        XCTAssertNil(NumericValue.positiveDouble(from: true))
        XCTAssertNil(NumericValue.positiveDouble(from: Double.infinity))
    }

    func testHexadecimalDoubleAcceptsPrefixedAndUnprefixedValues() {
        XCTAssertEqual(NumericValue.hexadecimalDouble(from: "0x2a"), 42)
        XCTAssertEqual(NumericValue.hexadecimalDouble(from: "2A"), 42)
        XCTAssertEqual(NumericValue.hexadecimalDouble(from: "0x0"), 0)
        XCTAssertEqual(
            NumericValue.hexadecimalDouble(from: "0xffffffffffffffff"),
            Double(UInt64.max)
        )
    }

    func testHexadecimalDoubleRejectsMalformedAndOverflowingValues() {
        XCTAssertNil(NumericValue.hexadecimalDouble(from: ""))
        XCTAssertNil(NumericValue.hexadecimalDouble(from: "0x"))
        XCTAssertNil(NumericValue.hexadecimalDouble(from: "0xnothex"))
        XCTAssertNil(NumericValue.hexadecimalDouble(from: "10000000000000000"))
        XCTAssertNil(NumericValue.hexadecimalDouble(from: "-1"))
    }
}
