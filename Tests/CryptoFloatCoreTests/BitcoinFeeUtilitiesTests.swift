import Foundation
import XCTest
@testable import CryptoFloatCore

final class BitcoinFeeUtilitiesTests: XCTestCase {
    func testMempoolBlocksParserUsesNormalRangeAndLaterBlockForSlowTier() throws {
        let parsed = try XCTUnwrap(
            BitcoinFeePayloadParser.mempoolBlocks(
                from: data("""
                    [
                      {"medianFee":2,"feeRange":[1,2,3,4,5,100]},
                      {"medianFee":1.5},
                      {"medianFee":1.25}
                    ]
                    """)
            )
        )

        XCTAssertEqual(
            parsed,
            BitcoinFeeEstimate(
                source: "mempool blocks",
                slow: 1.25,
                standard: 5,
                fast: 5
            )
        )
    }

    func testRecommendedBlockstreamAndBlockchairPayloadMappings() throws {
        XCTAssertEqual(
            BitcoinFeePayloadParser.mempoolRecommended(
                from: data("""
                    {"economyFee":1,"hourFee":2,"halfHourFee":3,"fastestFee":4}
                    """)
            ),
            BitcoinFeeEstimate(
                source: "mempool recommended",
                slow: 2,
                standard: 3,
                fast: 4
            )
        )
        XCTAssertEqual(
            BitcoinFeePayloadParser.blockstream(
                from: data("""
                    {"1":8,"3":5,"6":2}
                    """)
            ),
            BitcoinFeeEstimate(
                source: "Blockstream",
                slow: 2,
                standard: 5,
                fast: 8
            )
        )
        XCTAssertEqual(
            BitcoinFeePayloadParser.blockchair(
                from: data("""
                    {"data":{"suggested_transaction_fee_per_byte_sat":6}}
                    """)
            ),
            BitcoinFeeEstimate(
                source: "Blockchair",
                slow: 6,
                standard: 6,
                fast: 6
            )
        )
    }

    func testBlockcypherConvertsPerKilobyteValuesToSatPerVByte() {
        XCTAssertEqual(
            BitcoinFeePayloadParser.blockcypher(
                from: data("""
                    {
                      "low_fee_per_kb":1500,
                      "medium_fee_per_kb":2500,
                      "high_fee_per_kb":4000
                    }
                    """)
            ),
            BitcoinFeeEstimate(
                source: "BlockCypher",
                slow: 1.5,
                standard: 2.5,
                fast: 4
            )
        )
    }

    func testBitcoinerLiveRequiresFreshTimestampAndMapsConfidenceWindows() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let freshPayload = data("""
            {
              "timestamp":1699999900,
              "estimates":{
                "120":{"sat_per_vbyte":1.5},
                "60":{"sat_per_vbyte":2.5},
                "30":{"sat_per_vbyte":4}
              }
            }
            """)

        XCTAssertEqual(
            try XCTUnwrap(
                BitcoinFeePayloadParser.bitcoinerLive(
                    from: freshPayload,
                    now: now
                )
            ),
            BitcoinFeeEstimate(
                source: "Bitcoiner.live",
                slow: 1.5,
                standard: 2.5,
                fast: 4
            )
        )
        XCTAssertNil(
            BitcoinFeePayloadParser.bitcoinerLive(
                from: data("""
                    {"timestamp":1699978400,"estimates":{}}
                    """),
                now: now
            )
        )
        XCTAssertNil(
            BitcoinFeePayloadParser.bitcoinerLive(
                from: data("""
                    {"timestamp":1700000301,"estimates":{}}
                    """),
                now: now
            )
        )
    }

    func testConservativeEstimateRejectsOutlierAndKeepsTiersMonotonic() throws {
        let estimates = [
            BitcoinFeeEstimate(source: "A", slow: 1, standard: 2, fast: 3),
            BitcoinFeeEstimate(source: "B", slow: 1.2, standard: 2.2, fast: 3.2),
            BitcoinFeeEstimate(source: "C", slow: 1.4, standard: 2.4, fast: 3.4),
            BitcoinFeeEstimate(source: "outlier", slow: 900, standard: 900, fast: 900)
        ]

        let result = try XCTUnwrap(
            BitcoinFeeCalculator.conservativeEstimate(from: estimates)
        )

        XCTAssertEqual(result.slow, 1.4)
        XCTAssertEqual(result.standard, 2.4)
        XCTAssertEqual(result.fast, 3.4)

        let unordered = try XCTUnwrap(
            BitcoinFeeCalculator.conservativeEstimate(
                from: [
                    BitcoinFeeEstimate(
                        source: "single",
                        slow: 8,
                        standard: 3,
                        fast: 1
                    )
                ]
            )
        )
        XCTAssertEqual(unordered.slow, 8)
        XCTAssertEqual(unordered.standard, 8)
        XCTAssertEqual(unordered.fast, 8)
    }

    func testTierCalculatorUsesTypicalTransactionSizeAndValidPrice() throws {
        let estimate = BitcoinFeeEstimate(
            source: "fixture",
            slow: 1,
            standard: 2,
            fast: 3
        )

        let tiers = BitcoinFeeCalculator.tiers(
            from: estimate,
            btcPrice: 50_000
        )

        XCTAssertEqual(tiers.map(\.label), ["Slow", "Standard", "Fast"])
        XCTAssertEqual(tiers.map(\.rate), [1, 2, 3])
        XCTAssertEqual(try XCTUnwrap(tiers[0].usdValue), 0.07, accuracy: 0.000_001)
        XCTAssertEqual(try XCTUnwrap(tiers[1].usdValue), 0.14, accuracy: 0.000_001)
        XCTAssertEqual(try XCTUnwrap(tiers[2].usdValue), 0.21, accuracy: 0.000_001)

        XCTAssertTrue(
            BitcoinFeeCalculator.tiers(
                from: estimate,
                btcPrice: .nan
            ).allSatisfy { $0.usdValue == nil }
        )
    }

    func testPartialEstimatePreservesTheOriginalTierLabel() {
        let fastOnly = BitcoinFeeEstimate(
            source: "fixture",
            slow: nil,
            standard: nil,
            fast: 7
        )
        let standardOnly = BitcoinFeeEstimate(
            source: "fixture",
            slow: nil,
            standard: 4,
            fast: nil
        )

        XCTAssertEqual(
            BitcoinFeeCalculator.tiers(
                from: fastOnly,
                btcPrice: nil
            ).map(\.label),
            ["Fast"]
        )
        XCTAssertEqual(
            BitcoinFeeCalculator.tiers(
                from: standardOnly,
                btcPrice: nil
            ).map(\.label),
            ["Standard"]
        )
    }

    private func data(_ json: String) -> Data {
        return Data(json.utf8)
    }
}
