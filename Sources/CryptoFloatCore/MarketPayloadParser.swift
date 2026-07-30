import Foundation

enum MarketPayloadParser {
    static func kuCoinPrice(from data: Data) -> PriceData? {
        guard let json = jsonDictionary(from: data),
              json["code"] as? String == "200000",
              let payload = json["data"] as? [String: Any],
              let price = NumericValue.positiveDouble(from: payload["last"]) else {
            return nil
        }

        let change = NumericValue.finiteDouble(from: payload["changeRate"]).map { $0 * 100 }
        return PriceData(price: price, change24h: change, hasError: false)
    }

    static func binancePrice(from data: Data) -> PriceData? {
        guard let json = jsonDictionary(from: data),
              let price = NumericValue.positiveDouble(from: json["lastPrice"]) else {
            return nil
        }

        return PriceData(
            price: price,
            change24h: NumericValue.finiteDouble(from: json["priceChangePercent"]),
            hasError: false
        )
    }

    static func coinGeckoPrice(from data: Data, id: String) -> PriceData? {
        return coinGeckoPrices(from: data, idsBySymbol: [id: id])[id]
    }

    static func coinGeckoPrices(
        from data: Data,
        idsBySymbol: [String: String]
    ) -> [String: PriceData] {
        guard let json = jsonDictionary(from: data) else { return [:] }

        var prices: [String: PriceData] = [:]
        for (symbol, id) in idsBySymbol {
            guard let payload = json[id] as? [String: Any],
                  let price = NumericValue.positiveDouble(from: payload["usd"]) else {
                continue
            }

            prices[symbol] = PriceData(
                price: price,
                change24h: NumericValue.finiteDouble(from: payload["usd_24h_change"]),
                hasError: false
            )
        }
        return prices
    }

    static func kuCoinCandlePoints(from data: Data) -> [ChartPoint]? {
        guard let json = jsonDictionary(from: data),
              json["code"] as? String == "200000",
              let rows = json["data"] as? [[Any]] else {
            return nil
        }

        let points = rows.compactMap { row -> ChartPoint? in
            guard row.count > 2,
                  let time = NumericValue.positiveDouble(from: row[0]),
                  let price = NumericValue.positiveDouble(from: row[2]) else {
                return nil
            }
            return ChartPoint(time: time, price: price)
        }
        return SeriesUtilities.normalizedChartPoints(points)
    }

    static func binanceCandlePoints(from data: Data) -> [ChartPoint]? {
        guard let rows = try? JSONSerialization.jsonObject(with: data) as? [[Any]] else {
            return nil
        }

        let points = rows.compactMap { row -> ChartPoint? in
            guard row.count > 4,
                  let timeMilliseconds = NumericValue.positiveDouble(from: row[0]),
                  let price = NumericValue.positiveDouble(from: row[4]) else {
                return nil
            }
            return ChartPoint(time: timeMilliseconds / 1_000, price: price)
        }
        return SeriesUtilities.normalizedChartPoints(points)
    }

    static func coinGeckoMarketChartPoints(from data: Data) -> [ChartPoint]? {
        guard let json = jsonDictionary(from: data),
              let rows = json["prices"] as? [[Any]] else {
            return nil
        }

        let points = rows.compactMap { row -> ChartPoint? in
            guard row.count > 1,
                  let timeMilliseconds = NumericValue.positiveDouble(from: row[0]),
                  let price = NumericValue.positiveDouble(from: row[1]) else {
                return nil
            }
            return ChartPoint(time: timeMilliseconds / 1_000, price: price)
        }
        return SeriesUtilities.normalizedChartPoints(points)
    }

    private static func jsonDictionary(from data: Data) -> [String: Any]? {
        return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    }
}
