import Foundation
import XCTest
@testable import CryptoFloatCore

final class PriceSnapshotMergerTests: XCTestCase {
    func testFreshIncomingDataWinsAndCountsAsSuccessful() {
        let previous = PriceData(price: 100, change24h: 1, hasError: false)
        let incoming = PriceData(price: 110, change24h: 2, hasError: false)

        let result = PriceSnapshotMerger.merge(
            symbols: ["BTC"],
            incoming: ["BTC": incoming],
            previous: ["BTC": previous]
        )

        XCTAssertEqual(result.prices, ["BTC": incoming])
        XCTAssertEqual(result.successfulCount, 1)
    }

    func testFailedRefreshPreservesLastKnownValueAndMarksItStale() {
        let previous = PriceData(price: 100, change24h: -1.5, hasError: false)
        let failure = PriceData(price: 0, change24h: nil, hasError: true)

        let result = PriceSnapshotMerger.merge(
            symbols: ["BTC"],
            incoming: ["BTC": failure],
            previous: ["BTC": previous]
        )

        XCTAssertEqual(
            result.prices["BTC"],
            PriceData(price: 100, change24h: -1.5, hasError: true)
        )
        XCTAssertEqual(result.successfulCount, 0)
    }

    func testMissingIncomingValueUsesLastKnownValueAsStale() {
        let previous = PriceData(price: 2_000, change24h: 0.5, hasError: false)

        let result = PriceSnapshotMerger.merge(
            symbols: ["ETH"],
            incoming: [:],
            previous: ["ETH": previous]
        )

        XCTAssertEqual(
            result.prices["ETH"],
            PriceData(price: 2_000, change24h: 0.5, hasError: true)
        )
        XCTAssertEqual(result.successfulCount, 0)
    }

    func testFailureWithoutUsablePreviousDataRemainsUnavailable() {
        let failure = PriceData(price: 0, change24h: nil, hasError: true)

        let result = PriceSnapshotMerger.merge(
            symbols: ["SOL"],
            incoming: ["SOL": failure],
            previous: ["SOL": PriceData(price: 0, change24h: 4, hasError: false)]
        )

        XCTAssertEqual(result.prices["SOL"], failure)
        XCTAssertEqual(result.successfulCount, 0)
    }

    func testRemovedSymbolsDoNotSurviveMerge() {
        let liveBTC = PriceData(price: 100, change24h: 1, hasError: false)
        let previousETH = PriceData(price: 2_000, change24h: 2, hasError: false)

        let result = PriceSnapshotMerger.merge(
            symbols: ["BTC"],
            incoming: ["BTC": liveBTC, "ETH": previousETH],
            previous: ["ETH": previousETH]
        )

        XCTAssertEqual(result.prices, ["BTC": liveBTC])
        XCTAssertEqual(result.successfulCount, 1)
    }

    func testSuccessCountExcludesStaleValues() {
        let live = PriceData(price: 100, change24h: 1, hasError: false)
        let stale = PriceData(price: 2_000, change24h: 2, hasError: false)

        let result = PriceSnapshotMerger.merge(
            symbols: ["BTC", "ETH", "SOL"],
            incoming: ["BTC": live],
            previous: ["ETH": stale]
        )

        XCTAssertEqual(result.successfulCount, 1)
        XCTAssertFalse(try! XCTUnwrap(result.prices["BTC"]).hasError)
        XCTAssertTrue(try! XCTUnwrap(result.prices["ETH"]).hasError)
        XCTAssertTrue(try! XCTUnwrap(result.prices["SOL"]).hasError)
    }

    func testInvalidIncomingPriceCannotReplaceLastKnownGoodValue() {
        for invalidPrice in [0, -1, Double.nan, Double.infinity] {
            let result = PriceSnapshotMerger.merge(
                symbols: ["BTC"],
                incoming: [
                    "BTC": PriceData(
                        price: invalidPrice,
                        change24h: 99,
                        hasError: false
                    )
                ],
                previous: [
                    "BTC": PriceData(price: 100, change24h: 1, hasError: false)
                ]
            )

            XCTAssertEqual(
                result.prices["BTC"],
                PriceData(price: 100, change24h: 1, hasError: true)
            )
            XCTAssertEqual(result.successfulCount, 0)
        }
    }

    func testInvalidPreviousPriceIsNotPreserved() {
        for invalidPrice in [0, -1, Double.nan, Double.infinity] {
            let result = PriceSnapshotMerger.merge(
                symbols: ["BTC"],
                incoming: [:],
                previous: [
                    "BTC": PriceData(
                        price: invalidPrice,
                        change24h: 1,
                        hasError: false
                    )
                ]
            )

            XCTAssertEqual(
                result.prices["BTC"],
                PriceData(price: 0, change24h: nil, hasError: true)
            )
            XCTAssertEqual(result.successfulCount, 0)
        }
    }

    func testNonFiniteChangeIsDiscardedFromFreshAndStaleValues() {
        let fresh = PriceSnapshotMerger.merge(
            symbols: ["BTC"],
            incoming: [
                "BTC": PriceData(price: 100, change24h: .nan, hasError: false)
            ],
            previous: [:]
        )
        XCTAssertEqual(
            fresh.prices["BTC"],
            PriceData(price: 100, change24h: nil, hasError: false)
        )

        let stale = PriceSnapshotMerger.merge(
            symbols: ["BTC"],
            incoming: [:],
            previous: [
                "BTC": PriceData(price: 100, change24h: .infinity, hasError: false)
            ]
        )
        XCTAssertEqual(
            stale.prices["BTC"],
            PriceData(price: 100, change24h: nil, hasError: true)
        )
    }
}
