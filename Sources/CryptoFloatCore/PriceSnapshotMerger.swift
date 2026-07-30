import Foundation

struct PriceMergeResult: Equatable {
    let prices: [String: PriceData]
    let successfulCount: Int
}

enum PriceSnapshotMerger {
    static func merge(
        symbols: [String],
        incoming: [String: PriceData],
        previous: [String: PriceData]
    ) -> PriceMergeResult {
        var merged: [String: PriceData] = [:]
        var successfulCount = 0

        for symbol in symbols {
            let candidate = incoming[symbol]
                ?? PriceData(price: 0, change24h: nil, hasError: true)
            let candidateIsUsable = !candidate.hasError
                && candidate.price.isFinite
                && candidate.price > 0
            if candidateIsUsable {
                successfulCount += 1
                merged[symbol] = PriceData(
                    price: candidate.price,
                    change24h: candidate.change24h.flatMap { $0.isFinite ? $0 : nil },
                    hasError: false
                )
            } else if let prior = previous[symbol],
                      prior.price.isFinite,
                      prior.price > 0 {
                merged[symbol] = PriceData(
                    price: prior.price,
                    change24h: prior.change24h.flatMap { $0.isFinite ? $0 : nil },
                    hasError: true
                )
            } else {
                merged[symbol] = PriceData(
                    price: 0,
                    change24h: nil,
                    hasError: true
                )
            }
        }

        return PriceMergeResult(prices: merged, successfulCount: successfulCount)
    }
}
