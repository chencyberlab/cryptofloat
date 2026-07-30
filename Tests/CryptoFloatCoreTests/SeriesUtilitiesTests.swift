import Foundation
import XCTest
@testable import CryptoFloatCore

final class SeriesUtilitiesTests: XCTestCase {
    func testEvenSamplingHandlesBoundaryCounts() {
        let values = Array(0..<10)

        XCTAssertEqual(SeriesUtilities.evenlySampled(values, maximumCount: 0), [])
        XCTAssertEqual(SeriesUtilities.evenlySampled(values, maximumCount: 1), [9])
        XCTAssertEqual(SeriesUtilities.evenlySampled(values, maximumCount: 4), [0, 3, 6, 9])
        XCTAssertEqual(SeriesUtilities.evenlySampled([1, 2], maximumCount: 4), [1, 2])
        XCTAssertEqual(SeriesUtilities.evenlySampled([Int](), maximumCount: 4), [])
    }

    func testChartNormalizationFiltersSortsAndResolvesDuplicateTimestamps() {
        let points = [
            ChartPoint(time: 30, price: 3),
            ChartPoint(time: 10, price: 1),
            ChartPoint(time: 20, price: 2),
            ChartPoint(time: 20, price: 2.5),
            ChartPoint(time: 0, price: 10),
            ChartPoint(time: .nan, price: 10),
            ChartPoint(time: 40, price: -1),
            ChartPoint(time: 50, price: .infinity),
            ChartPoint(time: 101, price: 11)
        ]

        let normalized = SeriesUtilities.normalizedChartPoints(
            points,
            latestAllowedTime: 100
        )

        XCTAssertEqual(
            normalized,
            [
                ChartPoint(time: 10, price: 1),
                ChartPoint(time: 20, price: 2.5),
                ChartPoint(time: 30, price: 3)
            ]
        )
    }

    func testChartNormalizationAppliesMaximumAfterSorting() {
        let points = (1...10).reversed().map {
            ChartPoint(time: TimeInterval($0), price: Double($0))
        }

        let normalized = SeriesUtilities.normalizedChartPoints(
            points,
            maximumCount: 4,
            latestAllowedTime: 100
        )

        XCTAssertEqual(normalized.map(\.time), [1, 4, 7, 10])
        XCTAssertEqual(normalized.map(\.price), [1, 4, 7, 10])
    }

    func testChartNormalizationReturnsNoValuesForNonPositiveLimit() {
        let point = ChartPoint(time: 1, price: 1)
        XCTAssertEqual(
            SeriesUtilities.normalizedChartPoints(
                [point],
                maximumCount: 0,
                latestAllowedTime: 100
            ),
            []
        )
    }
}
