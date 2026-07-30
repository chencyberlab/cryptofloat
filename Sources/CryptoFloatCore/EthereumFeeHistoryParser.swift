import Foundation

struct EthereumFeeHistory: Equatable {
    let nextBaseFeeWei: Double
    let averagePriorityFeesWei: [Double]
}

enum EthereumFeeHistoryParser {
    static func parse(
        _ data: Data,
        expectedID: Double = 1,
        percentileCount: Int = 3,
        expectedBlockCount: Int? = nil
    ) -> EthereumFeeHistory? {
        guard percentileCount > 0,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["jsonrpc"] as? String == "2.0",
              NumericValue.finiteDouble(from: json["id"]) == expectedID,
              json["error"] == nil,
              let result = json["result"] as? [String: Any],
              let baseFeeStrings = result["baseFeePerGas"] as? [String],
              !baseFeeStrings.isEmpty,
              let rewardStrings = result["reward"] as? [[String]],
              !rewardStrings.isEmpty,
              baseFeeStrings.count == rewardStrings.count + 1 else {
            return nil
        }

        if let expectedBlockCount = expectedBlockCount {
            guard expectedBlockCount > 0,
                  rewardStrings.count == expectedBlockCount,
                  baseFeeStrings.count == expectedBlockCount + 1 else {
                return nil
            }
        }

        let baseFees = baseFeeStrings.compactMap(NumericValue.hexadecimalDouble)
        guard baseFees.count == baseFeeStrings.count,
              let nextBaseFeeWei = baseFees.last else {
            return nil
        }

        var rewardRows: [[Double]] = []
        rewardRows.reserveCapacity(rewardStrings.count)
        for row in rewardStrings {
            guard row.count == percentileCount else { return nil }
            let parsed = row.compactMap(NumericValue.hexadecimalDouble)
            guard parsed.count == percentileCount else { return nil }
            rewardRows.append(parsed)
        }

        let averages = (0..<percentileCount).map { percentileIndex in
            rewardRows.reduce(0) { $0 + $1[percentileIndex] } / Double(rewardRows.count)
        }
        return EthereumFeeHistory(
            nextBaseFeeWei: nextBaseFeeWei,
            averagePriorityFeesWei: averages
        )
    }
}
