import Foundation
import XCTest
@testable import CryptoFloatCore

final class MarketPayloadParserTests: XCTestCase {
    func testKuCoinPriceValidatesEnvelopeAndConvertsChangeRateToPercent() throws {
        let parsed = try XCTUnwrap(
            MarketPayloadParser.kuCoinPrice(
                from: data("""
                    {
                      "code": "200000",
                      "data": {"last": "64250.5", "changeRate": "0.0125"}
                    }
                    """)
            )
        )

        XCTAssertEqual(
            parsed,
            PriceData(price: 64_250.5, change24h: 1.25, hasError: false)
        )
        XCTAssertNil(
            MarketPayloadParser.kuCoinPrice(
                from: data("""
                    {"code":"500000","data":{"last":"64250.5"}}
                    """)
            )
        )
        XCTAssertNil(
            MarketPayloadParser.kuCoinPrice(
                from: data("""
                    {"code":"200000","data":{"last":true}}
                    """)
            )
        )
    }

    func testBinancePriceRejectsInvalidPricesAndDropsInvalidChange() throws {
        XCTAssertEqual(
            try XCTUnwrap(
                MarketPayloadParser.binancePrice(
                    from: data("""
                        {"lastPrice":"1924.25","priceChangePercent":"-2.5"}
                        """)
                )
            ),
            PriceData(price: 1_924.25, change24h: -2.5, hasError: false)
        )
        XCTAssertEqual(
            try XCTUnwrap(
                MarketPayloadParser.binancePrice(
                    from: data("""
                        {"lastPrice":"1924.25","priceChangePercent":false}
                        """)
                )
            ),
            PriceData(price: 1_924.25, change24h: nil, hasError: false)
        )
        XCTAssertNil(
            MarketPayloadParser.binancePrice(
                from: data("""
                    {"lastPrice":"0","priceChangePercent":"1"}
                    """)
            )
        )
    }

    func testCoinGeckoBulkParserMapsSymbolsAndKeepsValidPartialResults() {
        let parsed = MarketPayloadParser.coinGeckoPrices(
            from: data("""
                {
                  "bitcoin":{"usd":64250.5,"usd_24h_change":1.2},
                  "ethereum":{"usd":false,"usd_24h_change":2},
                  "solana":{"usd":"74.2","usd_24h_change":"NaN"}
                }
                """),
            idsBySymbol: [
                "BTC": "bitcoin",
                "ETH": "ethereum",
                "SOL": "solana",
                "DOGE": "dogecoin"
            ]
        )

        XCTAssertEqual(
            parsed["BTC"],
            PriceData(price: 64_250.5, change24h: 1.2, hasError: false)
        )
        XCTAssertEqual(
            parsed["SOL"],
            PriceData(price: 74.2, change24h: nil, hasError: false)
        )
        XCTAssertNil(parsed["ETH"])
        XCTAssertNil(parsed["DOGE"])
    }

    func testKuCoinCandlesUseSecondTimestampsAndSortChronologically() throws {
        let points = try XCTUnwrap(
            MarketPayloadParser.kuCoinCandlePoints(
                from: data("""
                    {
                      "code":"200000",
                      "data":[
                        ["1700007200","0","103"],
                        [true,"0","999"],
                        ["1700000000","0","101"],
                        ["1700003600","0","102"],
                        ["1700003600","0","102.5"]
                      ]
                    }
                    """)
            )
        )

        XCTAssertEqual(
            points,
            [
                ChartPoint(time: 1_700_000_000, price: 101),
                ChartPoint(time: 1_700_003_600, price: 102.5),
                ChartPoint(time: 1_700_007_200, price: 103)
            ]
        )
    }

    func testBinanceCandlesConvertMillisecondsAndRejectBooleanTimestamp() throws {
        let points = try XCTUnwrap(
            MarketPayloadParser.binanceCandlePoints(
                from: data("""
                    [
                      [1700003600000,"0","0","0","102"],
                      [true,"0","0","0","999"],
                      [1700000000000,"0","0","0","101"]
                    ]
                    """)
            )
        )

        XCTAssertEqual(
            points,
            [
                ChartPoint(time: 1_700_000_000, price: 101),
                ChartPoint(time: 1_700_003_600, price: 102)
            ]
        )
    }

    func testCoinGeckoMarketChartConvertsMillisecondsAndDropsInvalidRows() throws {
        let points = try XCTUnwrap(
            MarketPayloadParser.coinGeckoMarketChartPoints(
                from: data("""
                    {
                      "prices":[
                        [1700000000000,101],
                        [1700003600000,102],
                        [1700007200000,false],
                        [true,999]
                      ]
                    }
                    """)
            )
        )

        XCTAssertEqual(
            points,
            [
                ChartPoint(time: 1_700_000_000, price: 101),
                ChartPoint(time: 1_700_003_600, price: 102)
            ]
        )
    }

    private func data(_ json: String) -> Data {
        return Data(json.utf8)
    }
}
