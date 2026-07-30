import Foundation

struct BitcoinFeeEstimate: Equatable {
    let source: String
    let slow: Double?
    let standard: Double?
    let fast: Double?
}

enum BitcoinFeePayloadParser {
    static func mempoolBlocks(from data: Data) -> BitcoinFeeEstimate? {
        guard let blocks = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let firstBlock = blocks.first else {
            return nil
        }

        let feeRange = (firstBlock["feeRange"] as? [Any])?
            .compactMap { NumericValue.finiteDouble(from: $0) } ?? []
        let firstMedian = NumericValue.finiteDouble(from: firstBlock["medianFee"])
        let thirdBlockMedian = blocks.dropFirst(2).first.flatMap {
            NumericValue.finiteDouble(from: $0["medianFee"])
        }
        let lastBlockMedian = blocks.last.flatMap {
            NumericValue.finiteDouble(from: $0["medianFee"])
        }
        let upperNormalFee = feeRange.count >= 2
            ? feeRange[feeRange.count - 2]
            : feeRange.last

        let slow = thirdBlockMedian ?? lastBlockMedian ?? feeRange.first ?? firstMedian
        let standard = feeRange.indices.contains(4)
            ? max(firstMedian ?? 0, feeRange[4])
            : firstMedian
        let fast = upperNormalFee ?? firstMedian

        return BitcoinFeeEstimate(
            source: "mempool blocks",
            slow: slow,
            standard: standard,
            fast: fast
        )
    }

    static func mempoolRecommended(from data: Data) -> BitcoinFeeEstimate? {
        guard let json = jsonDictionary(from: data) else { return nil }
        return BitcoinFeeEstimate(
            source: "mempool recommended",
            slow: NumericValue.finiteDouble(from: json["hourFee"])
                ?? NumericValue.finiteDouble(from: json["economyFee"]),
            standard: NumericValue.finiteDouble(from: json["halfHourFee"]),
            fast: NumericValue.finiteDouble(from: json["fastestFee"])
        )
    }

    static func blockstream(from data: Data) -> BitcoinFeeEstimate? {
        guard let json = jsonDictionary(from: data) else { return nil }
        return BitcoinFeeEstimate(
            source: "Blockstream",
            slow: NumericValue.finiteDouble(from: json["6"])
                ?? NumericValue.finiteDouble(from: json["12"])
                ?? NumericValue.finiteDouble(from: json["24"]),
            standard: NumericValue.finiteDouble(from: json["3"])
                ?? NumericValue.finiteDouble(from: json["4"])
                ?? NumericValue.finiteDouble(from: json["6"]),
            fast: NumericValue.finiteDouble(from: json["1"])
                ?? NumericValue.finiteDouble(from: json["2"])
        )
    }

    static func blockchair(from data: Data) -> BitcoinFeeEstimate? {
        guard let json = jsonDictionary(from: data),
              let stats = json["data"] as? [String: Any],
              let suggested = NumericValue.finiteDouble(
                  from: stats["suggested_transaction_fee_per_byte_sat"]
              ) else {
            return nil
        }
        return BitcoinFeeEstimate(
            source: "Blockchair",
            slow: suggested,
            standard: suggested,
            fast: suggested
        )
    }

    static func blockcypher(from data: Data) -> BitcoinFeeEstimate? {
        guard let json = jsonDictionary(from: data) else { return nil }
        return BitcoinFeeEstimate(
            source: "BlockCypher",
            slow: NumericValue.finiteDouble(from: json["low_fee_per_kb"]).map { $0 / 1_000 },
            standard: NumericValue.finiteDouble(from: json["medium_fee_per_kb"]).map { $0 / 1_000 },
            fast: NumericValue.finiteDouble(from: json["high_fee_per_kb"]).map { $0 / 1_000 }
        )
    }

    static func bitcoinerLive(
        from data: Data,
        now: Date = Date()
    ) -> BitcoinFeeEstimate? {
        let nowTimestamp = now.timeIntervalSince1970
        guard let json = jsonDictionary(from: data),
              let timestamp = NumericValue.finiteDouble(from: json["timestamp"]),
              timestamp <= nowTimestamp + 5 * 60,
              nowTimestamp - timestamp < 6 * 60 * 60,
              let estimates = json["estimates"] as? [String: Any] else {
            return nil
        }

        func rate(_ minutes: String) -> Double? {
            guard let estimate = estimates[minutes] as? [String: Any] else { return nil }
            return NumericValue.finiteDouble(from: estimate["sat_per_vbyte"])
        }

        return BitcoinFeeEstimate(
            source: "Bitcoiner.live",
            slow: rate("120") ?? rate("180") ?? rate("360"),
            standard: rate("60"),
            fast: rate("30")
        )
    }

    private static func jsonDictionary(from data: Data) -> [String: Any]? {
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}

enum BitcoinFeeCalculator {
    static func conservativeEstimate(
        from estimates: [BitcoinFeeEstimate]
    ) -> BitcoinFeeEstimate? {
        guard !estimates.isEmpty else { return nil }

        let slow = FeeRateEstimator.conservativeRate(estimates.map(\.slow))
        let standardBase = FeeRateEstimator.conservativeRate(estimates.map(\.standard))
        let fastBase = FeeRateEstimator.conservativeRate(estimates.map(\.fast))
        let standard = [standardBase, slow].compactMap { $0 }.max()
        let fast = [fastBase, standard].compactMap { $0 }.max()

        return BitcoinFeeEstimate(
            source: estimates.map(\.source).joined(separator: ", "),
            slow: slow,
            standard: standard,
            fast: fast
        )
    }

    static func tiers(
        from estimate: BitcoinFeeEstimate,
        btcPrice: Double?,
        typicalVBytes: Double = 140,
        etas: (String, String, String) = ("~30-60m", "~10-30m", "next block")
    ) -> [NetworkFeeTier] {
        let validBTCPrice = btcPrice.flatMap {
            $0.isFinite && $0 > 0 ? $0 : nil
        }
        let transactionSize = typicalVBytes.isFinite && typicalVBytes > 0
            ? typicalVBytes
            : 140
        let raw: [(String, Double?, String)] = [
            ("Slow", estimate.slow, etas.0),
            ("Standard", estimate.standard, etas.1),
            ("Fast", estimate.fast, etas.2)
        ]

        return raw.compactMap { label, rate, eta -> NetworkFeeTier? in
            guard let rate = rate,
                  rate.isFinite,
                  rate > 0 else {
                return nil
            }
            let satoshis = rate * transactionSize
            let usdValue = validBTCPrice.map {
                satoshis / 100_000_000 * $0
            }
            return NetworkFeeTier(
                label: label,
                rate: rate,
                unit: "sat/vB",
                usdValue: usdValue,
                eta: eta
            )
        }
    }
}
