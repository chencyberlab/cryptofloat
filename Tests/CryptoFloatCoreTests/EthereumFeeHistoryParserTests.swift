import Foundation
import XCTest
@testable import CryptoFloatCore

final class EthereumFeeHistoryParserTests: XCTestCase {
    func testParsesBaseFeeAndAveragesPriorityFeePercentiles() throws {
        let data = Data(
            """
            {
              "jsonrpc": "2.0",
              "id": 1,
              "result": {
                "baseFeePerGas": ["0x3b9aca00", "0x3b9aca00", "0x77359400"],
                "reward": [
                  ["0x3b9aca00", "0x77359400", "0xb2d05e00"],
                  ["0x77359400", "0xb2d05e00", "0xee6b2800"]
                ]
              }
            }
            """.utf8
        )

        let history = try XCTUnwrap(EthereumFeeHistoryParser.parse(data))

        XCTAssertEqual(history.nextBaseFeeWei, 2_000_000_000)
        XCTAssertEqual(
            history.averagePriorityFeesWei,
            [1_500_000_000, 2_500_000_000, 3_500_000_000]
        )
    }

    func testRejectsWrongEnvelopeVersionIDAndExplicitError() {
        XCTAssertNil(parse("""
            {"jsonrpc":"1.0","id":1,"result":{"baseFeePerGas":["0x1","0x2"],"reward":[["0x1","0x2","0x3"]]}}
            """))
        XCTAssertNil(parse("""
            {"jsonrpc":"2.0","id":2,"result":{"baseFeePerGas":["0x1","0x2"],"reward":[["0x1","0x2","0x3"]]}}
            """))
        XCTAssertNil(parse("""
            {"jsonrpc":"2.0","id":1,"error":{"code":-32603},"result":{"baseFeePerGas":["0x1","0x2"],"reward":[["0x1","0x2","0x3"]]}}
            """))
    }

    func testRejectsMalformedBaseFeeSoCallerCanTryNextEndpoint() {
        XCTAssertNil(parse("""
            {"jsonrpc":"2.0","id":1,"result":{"baseFeePerGas":["0x1","not-hex"],"reward":[["0x1","0x2","0x3"]]}}
            """))
        XCTAssertNil(parse("""
            {"jsonrpc":"2.0","id":1,"result":{"baseFeePerGas":[],"reward":[["0x1","0x2","0x3"]]}}
            """))
        XCTAssertNil(parse("""
            {"jsonrpc":"2.0","id":1,"result":{"baseFeePerGas":["0x1"],"reward":[["0x1","0x2","0x3"]]}}
            """))
        XCTAssertNil(parse("""
            {"jsonrpc":"2.0","id":1,"result":{"baseFeePerGas":["0x1","0x2","0x3"],"reward":[["0x1","0x2","0x3"]]}}
            """))
    }

    func testRejectsMissingMalformedOrUndersizedRewardRows() {
        XCTAssertNil(parse("""
            {"jsonrpc":"2.0","id":1,"result":{"baseFeePerGas":["0x1"],"reward":[]}}
            """))
        XCTAssertNil(parse("""
            {"jsonrpc":"2.0","id":1,"result":{"baseFeePerGas":["0x1","0x2"],"reward":[["0x1","0x2"]]}}
            """))
        XCTAssertNil(parse("""
            {"jsonrpc":"2.0","id":1,"result":{"baseFeePerGas":["0x1","0x2"],"reward":[["0x1","not-hex","0x3"]]}}
            """))
        XCTAssertNil(parse("""
            {"jsonrpc":"2.0","id":1,"result":{"baseFeePerGas":["0x1","0x2"],"reward":[["0x1","0x2","0x3","0x4"]]}}
            """))
    }

    func testSupportsExplicitExpectedIDAndPercentileCount() throws {
        let history = try XCTUnwrap(parse(
            """
            {"jsonrpc":"2.0","id":7,"result":{"baseFeePerGas":["0x8","0xa"],"reward":[["0x2","0x4"]]}}
            """,
            expectedID: 7,
            percentileCount: 2
        ))

        XCTAssertEqual(history.nextBaseFeeWei, 10)
        XCTAssertEqual(history.averagePriorityFeesWei, [2, 4])
        XCTAssertNil(parse(
            """
            {"jsonrpc":"2.0","id":7,"result":{"baseFeePerGas":["0x8","0xa"],"reward":[["0x2","0x4"]]}}
            """,
            expectedID: 7,
            percentileCount: 0
        ))
    }

    func testExpectedBlockCountMustMatchRequestShape() throws {
        let valid = """
            {
              "jsonrpc":"2.0",
              "id":1,
              "result":{
                "baseFeePerGas":["0x1","0x2","0x3"],
                "reward":[["0x1","0x2","0x3"],["0x2","0x3","0x4"]]
              }
            }
            """

        XCTAssertNotNil(parse(valid, expectedBlockCount: 2))
        XCTAssertNil(parse(valid, expectedBlockCount: 1))
        XCTAssertNil(parse(valid, expectedBlockCount: 0))
    }

    private func parse(
        _ json: String,
        expectedID: Double = 1,
        percentileCount: Int = 3,
        expectedBlockCount: Int? = nil
    ) -> EthereumFeeHistory? {
        return EthereumFeeHistoryParser.parse(
            Data(json.utf8),
            expectedID: expectedID,
            percentileCount: percentileCount,
            expectedBlockCount: expectedBlockCount
        )
    }
}
