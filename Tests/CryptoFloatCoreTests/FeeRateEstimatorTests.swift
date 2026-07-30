import Foundation
import XCTest
@testable import CryptoFloatCore

final class FeeRateEstimatorTests: XCTestCase {
    func testConservativeRateRejectsInvalidCandidates() {
        XCTAssertNil(
            FeeRateEstimator.conservativeRate([
                nil,
                -1,
                0,
                .nan,
                .infinity,
                1_000
            ])
        )
    }

    func testOneOrTwoValidCandidatesUseTheHighest() {
        XCTAssertEqual(FeeRateEstimator.conservativeRate([4]), 4)
        XCTAssertEqual(FeeRateEstimator.conservativeRate([4, 7]), 7)
        XCTAssertEqual(FeeRateEstimator.conservativeRate([7, 4]), 7)
    }

    func testUpperQuartileDoesNotAllowSingleOutlierToDominateSmallSample() {
        XCTAssertEqual(FeeRateEstimator.conservativeRate([1, 2, 999]), 2)
        XCTAssertEqual(FeeRateEstimator.conservativeRate([1, 2, 3, 999]), 3)
        XCTAssertEqual(FeeRateEstimator.conservativeRate([1, 2, 3, 4, 999]), 4)
    }

    func testConservativeRateFiltersBeforeCalculatingPercentile() {
        XCTAssertEqual(
            FeeRateEstimator.conservativeRate([
                nil,
                -5,
                1,
                2,
                3,
                999,
                1_000,
                .infinity
            ]),
            3
        )
    }
}
