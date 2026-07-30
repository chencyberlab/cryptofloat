import Foundation

// MARK: - Market Data API Manager
class CryptoAPI {
    static let shared = CryptoAPI()
    private let kuCoinBaseURL = "https://api.kucoin.com"
    private let binanceBaseURL = "https://data-api.binance.vision"
    private let coinGeckoBaseURL = "https://api.coingecko.com/api/v3"
    private let session: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = false
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration)
    }()

    private let coinGeckoIDs: [String: String] = [
        "BTC": "bitcoin",
        "ETH": "ethereum",
        "SOL": "solana",
        "ADA": "cardano",
        "DOGE": "dogecoin",
        "XRP": "ripple",
        "DOT": "polkadot",
        "AVAX": "avalanche-2",
        "LINK": "chainlink",
        "MATIC": "matic-network",
        "POL": "polygon-ecosystem-token",
        "BNB": "binancecoin",
        "LTC": "litecoin",
        "BCH": "bitcoin-cash",
        "SHIB": "shiba-inu",
        "PEPE": "pepe",
        "UNI": "uniswap",
        "AAVE": "aave",
        "NEAR": "near",
        "ATOM": "cosmos",
        "ETC": "ethereum-classic",
        "FIL": "filecoin",
        "TRX": "tron",
        "TON": "the-open-network",
        "OKB": "okb"
    ]

    private func errorPrice() -> PriceData {
        return PriceData(price: 0, change24h: nil, hasError: true)
    }

    private func errorPrices(for symbols: [String]) -> [String: PriceData] {
        var results: [String: PriceData] = [:]
        for symbol in symbols {
            results[symbol] = errorPrice()
        }
        return results
    }

    private func makeURL(baseURL: String, path: String, queryItems: [URLQueryItem]) -> URL? {
        guard var components = URLComponents(string: baseURL) else { return nil }
        components.path = path
        components.queryItems = queryItems
        return components.url
    }

    private func deliverOnMain<T>(_ value: T, to completion: @escaping (T) -> Void) {
        if Thread.isMainThread {
            completion(value)
        } else {
            DispatchQueue.main.async {
                completion(value)
            }
        }
    }

    private func request(_ url: URL, completion: @escaping (Data?) -> Void) {
        var request = URLRequest(url: url)
        request.setValue("CryptoFloat/1.1", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let response = response as? HTTPURLResponse,
                  (200..<300).contains(response.statusCode),
                  let data = data,
                  !data.isEmpty,
                  data.count <= 5_000_000 else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                print("Market data request failed with HTTP status \(status)")
                completion(nil)
                return
            }

            completion(data)
        }.resume()
    }

    private func coinGeckoID(for symbol: String) -> String? {
        return coinGeckoIDs[symbol.uppercased()]
    }

    func fetchPrice(for symbol: String, provider: DataProvider, completion: @escaping (PriceData) -> Void) {
        let delivered: (PriceData) -> Void = { [weak self] value in
            self?.deliverOnMain(value, to: completion)
        }
        switch provider {
        case .kuCoin:
            fetchKuCoinPrice(for: symbol, completion: delivered)
        case .binance:
            fetchBinancePrice(for: symbol, completion: delivered)
        case .coinGecko:
            fetchCoinGeckoPrice(for: symbol, completion: delivered)
        }
    }

    private func fetchKuCoinPrice(for symbol: String, completion: @escaping (PriceData) -> Void) {
        let pair = "\(symbol.uppercased())-USDT"
        guard let url = makeURL(
            baseURL: kuCoinBaseURL,
            path: "/api/v1/market/stats",
            queryItems: [URLQueryItem(name: "symbol", value: pair)]
        ) else {
            completion(errorPrice())
            return
        }

        request(url) { data in
            guard let data = data,
                  let price = MarketPayloadParser.kuCoinPrice(from: data) else {
                completion(self.errorPrice())
                return
            }
            completion(price)
        }
    }

    private func fetchBinancePrice(for symbol: String, completion: @escaping (PriceData) -> Void) {
        let pair = "\(symbol.uppercased())USDT"
        guard let url = makeURL(
            baseURL: binanceBaseURL,
            path: "/api/v3/ticker/24hr",
            queryItems: [URLQueryItem(name: "symbol", value: pair)]
        ) else {
            completion(errorPrice())
            return
        }

        request(url) { data in
            guard let data = data,
                  let price = MarketPayloadParser.binancePrice(from: data) else {
                completion(self.errorPrice())
                return
            }
            completion(price)
        }
    }

    private func fetchCoinGeckoPrice(for symbol: String, completion: @escaping (PriceData) -> Void) {
        guard let id = coinGeckoID(for: symbol) else {
            completion(errorPrice())
            return
        }

        var components = URLComponents(string: "\(coinGeckoBaseURL)/simple/price")
        components?.queryItems = [
            URLQueryItem(name: "ids", value: id),
            URLQueryItem(name: "vs_currencies", value: "usd"),
            URLQueryItem(name: "include_24hr_change", value: "true")
        ]

        guard let url = components?.url else {
            completion(errorPrice())
            return
        }

        request(url) { data in
            guard let data = data,
                  let price = MarketPayloadParser.coinGeckoPrice(from: data, id: id) else {
                completion(self.errorPrice())
                return
            }
            completion(price)
        }
    }

    func fetchAllPrices(for symbols: [String], provider: DataProvider, completion: @escaping ([String: PriceData]) -> Void) {
        if provider == .coinGecko {
            fetchCoinGeckoAllPrices(for: symbols) { [weak self] results in
                self?.deliverOnMain(results, to: completion)
            }
            return
        }

        let group = DispatchGroup()
        var results: [String: PriceData] = [:]
        let lock = NSLock()

        for symbol in symbols {
            group.enter()
            fetchPrice(for: symbol, provider: provider) { data in
                lock.lock()
                results[symbol] = data
                lock.unlock()
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(results)
        }
    }

    private func fetchCoinGeckoAllPrices(for symbols: [String], completion: @escaping ([String: PriceData]) -> Void) {
        let pairs = symbols.compactMap { symbol -> (symbol: String, id: String)? in
            guard let id = coinGeckoID(for: symbol) else { return nil }
            return (symbol, id)
        }

        guard !pairs.isEmpty else {
            completion(errorPrices(for: symbols))
            return
        }

        var components = URLComponents(string: "\(coinGeckoBaseURL)/simple/price")
        components?.queryItems = [
            URLQueryItem(name: "ids", value: pairs.map { $0.id }.joined(separator: ",")),
            URLQueryItem(name: "vs_currencies", value: "usd"),
            URLQueryItem(name: "include_24hr_change", value: "true")
        ]

        guard let url = components?.url else {
            completion(errorPrices(for: symbols))
            return
        }

        request(url) { data in
            var results = self.errorPrices(for: symbols)

            guard let data = data else {
                completion(results)
                return
            }
            let parsed = MarketPayloadParser.coinGeckoPrices(
                from: data,
                idsBySymbol: Dictionary(
                    uniqueKeysWithValues: pairs.map { ($0.symbol, $0.id) }
                )
            )
            for (symbol, price) in parsed {
                results[symbol] = price
            }

            completion(results)
        }
    }

    /// Fetches ~24h of hourly closing prices for a tiny trend sparkline.
    /// Returns an empty array on any failure so the UI can simply skip drawing.
    func fetchSparkline(for symbol: String, provider: DataProvider, completion: @escaping ([Double]) -> Void) {
        let delivered: ([Double]) -> Void = { [weak self] values in
            self?.deliverOnMain(values, to: completion)
        }
        switch provider {
        case .kuCoin:
            fetchKuCoinSparkline(for: symbol, completion: delivered)
        case .binance:
            fetchBinanceSparkline(for: symbol, completion: delivered)
        case .coinGecko:
            fetchCoinGeckoSparkline(for: symbol, completion: delivered)
        }
    }

    private func fetchKuCoinSparkline(for symbol: String, completion: @escaping ([Double]) -> Void) {
        let pair = "\(symbol.uppercased())-USDT"
        let end = Int(Date().timeIntervalSince1970)
        let start = end - 60 * 60 * 26  // 26h window to comfortably capture 24 hourly candles
        guard let url = makeURL(
            baseURL: kuCoinBaseURL,
            path: "/api/v1/market/candles",
            queryItems: [
                URLQueryItem(name: "type", value: "1hour"),
                URLQueryItem(name: "symbol", value: pair),
                URLQueryItem(name: "startAt", value: "\(start)"),
                URLQueryItem(name: "endAt", value: "\(end)")
            ]
        ) else {
            DispatchQueue.main.async { completion([]) }
            return
        }

        request(url) { data in
            guard let data = data,
                  let points = MarketPayloadParser.kuCoinCandlePoints(from: data) else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            completion(Array(points.suffix(25)).map(\.price))
        }
    }

    private func fetchBinanceSparkline(for symbol: String, completion: @escaping ([Double]) -> Void) {
        let pair = "\(symbol.uppercased())USDT"
        guard let url = makeURL(
            baseURL: binanceBaseURL,
            path: "/api/v3/klines",
            queryItems: [
                URLQueryItem(name: "symbol", value: pair),
                URLQueryItem(name: "interval", value: "1h"),
                URLQueryItem(name: "limit", value: "25")
            ]
        ) else {
            DispatchQueue.main.async { completion([]) }
            return
        }

        request(url) { data in
            guard let data = data,
                  let points = MarketPayloadParser.binanceCandlePoints(from: data) else {
                completion([])
                return
            }
            completion(Array(points.suffix(25)).map(\.price))
        }
    }

    private func fetchCoinGeckoSparkline(for symbol: String, completion: @escaping ([Double]) -> Void) {
        fetchCoinGeckoMarketChart(for: symbol, days: 1) { points in
            completion(SeriesUtilities.evenlySampled(points.map(\.price), maximumCount: 32))
        }
    }

    /// Fetches 7 days of two-hour closing prices for the detail popup chart.
    /// Returns an empty array on any failure so the popup can show a soft error state.
    func fetchSevenDayChart(for symbol: String, provider: DataProvider, completion: @escaping ([ChartPoint]) -> Void) {
        let delivered: ([ChartPoint]) -> Void = { [weak self] points in
            self?.deliverOnMain(points, to: completion)
        }
        switch provider {
        case .kuCoin:
            fetchKuCoinSevenDayChart(for: symbol, completion: delivered)
        case .binance:
            fetchBinanceSevenDayChart(for: symbol, completion: delivered)
        case .coinGecko:
            fetchCoinGeckoMarketChart(for: symbol, days: 7) { points in
                delivered(SeriesUtilities.evenlySampled(points, maximumCount: 90))
            }
        }
    }

    private func fetchKuCoinSevenDayChart(for symbol: String, completion: @escaping ([ChartPoint]) -> Void) {
        let pair = "\(symbol.uppercased())-USDT"
        let end = Int(Date().timeIntervalSince1970)
        let start = end - 60 * 60 * 24 * 7
        guard let url = makeURL(
            baseURL: kuCoinBaseURL,
            path: "/api/v1/market/candles",
            queryItems: [
                URLQueryItem(name: "type", value: "2hour"),
                URLQueryItem(name: "symbol", value: pair),
                URLQueryItem(name: "startAt", value: "\(start)"),
                URLQueryItem(name: "endAt", value: "\(end)")
            ]
        ) else {
            DispatchQueue.main.async { completion([]) }
            return
        }

        request(url) { data in
            guard let data = data,
                  let points = MarketPayloadParser.kuCoinCandlePoints(from: data) else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            completion(Array(points.suffix(90)))
        }
    }

    private func fetchBinanceSevenDayChart(for symbol: String, completion: @escaping ([ChartPoint]) -> Void) {
        let pair = "\(symbol.uppercased())USDT"
        guard let url = makeURL(
            baseURL: binanceBaseURL,
            path: "/api/v3/klines",
            queryItems: [
                URLQueryItem(name: "symbol", value: pair),
                URLQueryItem(name: "interval", value: "2h"),
                URLQueryItem(name: "limit", value: "84")
            ]
        ) else {
            DispatchQueue.main.async { completion([]) }
            return
        }

        request(url) { data in
            guard let data = data,
                  let points = MarketPayloadParser.binanceCandlePoints(from: data) else {
                completion([])
                return
            }
            completion(points)
        }
    }

    private func fetchCoinGeckoMarketChart(for symbol: String, days: Int, completion: @escaping ([ChartPoint]) -> Void) {
        guard let id = coinGeckoID(for: symbol) else {
            DispatchQueue.main.async { completion([]) }
            return
        }

        var components = URLComponents(string: "\(coinGeckoBaseURL)/coins/\(id)/market_chart")
        components?.queryItems = [
            URLQueryItem(name: "vs_currency", value: "usd"),
            URLQueryItem(name: "days", value: "\(days)")
        ]

        guard let url = components?.url else {
            DispatchQueue.main.async { completion([]) }
            return
        }

        request(url) { data in
            guard let data = data,
                  let points = MarketPayloadParser.coinGeckoMarketChartPoints(from: data) else {
                completion([])
                return
            }
            completion(points)
        }
    }
}
