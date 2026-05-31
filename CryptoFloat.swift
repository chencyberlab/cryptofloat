import Cocoa
import Foundation

// MARK: - Themes
enum AppThemeName: String, Codable, CaseIterable {
    case cryptoFloat
    case tokyoNight
    case dracula
    case nord
    case catppuccinMocha
    case oneDarkPro
    case everforestDark
    case gruvboxDark
    case cyberpunkNeon
}

struct RGBColor {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat

    init(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    func color(alpha: CGFloat = 1) -> NSColor {
        return NSColor(calibratedRed: red / 255, green: green / 255, blue: blue / 255, alpha: alpha)
    }
}

struct AppTheme {
    let id: AppThemeName
    let displayName: String
    let background: RGBColor
    let backgroundDark: RGBColor
    let foreground: RGBColor
    let accent: RGBColor
    let accentSecondary: RGBColor
    let positive: RGBColor
    let negative: RGBColor
    let warning: RGBColor
}

enum ThemeCatalog {
    static var current = theme(for: .cryptoFloat)

    static let all: [AppTheme] = AppThemeName.allCases.map { theme(for: $0) }

    static func theme(for name: AppThemeName) -> AppTheme {
        switch name {
        case .cryptoFloat:
            return AppTheme(
                id: name,
                displayName: "CryptoFloat Default",
                background: RGBColor(31, 43, 69),
                backgroundDark: RGBColor(13, 17, 28),
                foreground: RGBColor(248, 250, 255),
                accent: RGBColor(122, 162, 247),
                accentSecondary: RGBColor(125, 207, 255),
                positive: RGBColor(77, 230, 140),
                negative: RGBColor(255, 107, 107),
                warning: RGBColor(224, 175, 104)
            )
        case .tokyoNight:
            return AppTheme(
                id: name,
                displayName: "Tokyo Night",
                background: RGBColor(26, 27, 38),
                backgroundDark: RGBColor(22, 22, 30),
                foreground: RGBColor(192, 202, 245),
                accent: RGBColor(122, 162, 247),
                accentSecondary: RGBColor(125, 207, 255),
                positive: RGBColor(158, 206, 106),
                negative: RGBColor(247, 118, 142),
                warning: RGBColor(224, 175, 104)
            )
        case .dracula:
            return AppTheme(
                id: name,
                displayName: "Dracula",
                background: RGBColor(40, 42, 54),
                backgroundDark: RGBColor(68, 71, 90),
                foreground: RGBColor(248, 248, 242),
                accent: RGBColor(189, 147, 249),
                accentSecondary: RGBColor(139, 233, 253),
                positive: RGBColor(80, 250, 123),
                negative: RGBColor(255, 121, 198),
                warning: RGBColor(255, 184, 108)
            )
        case .nord:
            return AppTheme(
                id: name,
                displayName: "Nord",
                background: RGBColor(46, 52, 64),
                backgroundDark: RGBColor(36, 41, 51),
                foreground: RGBColor(236, 239, 244),
                accent: RGBColor(136, 192, 208),
                accentSecondary: RGBColor(143, 188, 187),
                positive: RGBColor(163, 190, 140),
                negative: RGBColor(191, 97, 106),
                warning: RGBColor(235, 203, 139)
            )
        case .catppuccinMocha:
            return AppTheme(
                id: name,
                displayName: "Catppuccin Mocha",
                background: RGBColor(30, 30, 46),
                backgroundDark: RGBColor(17, 17, 27),
                foreground: RGBColor(205, 214, 244),
                accent: RGBColor(137, 180, 250),
                accentSecondary: RGBColor(180, 190, 254),
                positive: RGBColor(166, 227, 161),
                negative: RGBColor(243, 139, 168),
                warning: RGBColor(249, 226, 175)
            )
        case .oneDarkPro:
            return AppTheme(
                id: name,
                displayName: "One Dark Pro",
                background: RGBColor(40, 44, 52),
                backgroundDark: RGBColor(33, 37, 43),
                foreground: RGBColor(171, 178, 191),
                accent: RGBColor(97, 175, 239),
                accentSecondary: RGBColor(86, 182, 194),
                positive: RGBColor(152, 195, 121),
                negative: RGBColor(224, 108, 117),
                warning: RGBColor(229, 192, 123)
            )
        case .everforestDark:
            return AppTheme(
                id: name,
                displayName: "Everforest Dark",
                background: RGBColor(45, 53, 59),
                backgroundDark: RGBColor(39, 46, 51),
                foreground: RGBColor(211, 198, 170),
                accent: RGBColor(127, 187, 179),
                accentSecondary: RGBColor(131, 192, 146),
                positive: RGBColor(167, 192, 128),
                negative: RGBColor(230, 126, 128),
                warning: RGBColor(219, 188, 127)
            )
        case .gruvboxDark:
            return AppTheme(
                id: name,
                displayName: "Gruvbox Dark",
                background: RGBColor(40, 40, 40),
                backgroundDark: RGBColor(29, 32, 33),
                foreground: RGBColor(235, 219, 178),
                accent: RGBColor(214, 93, 14),
                accentSecondary: RGBColor(69, 133, 136),
                positive: RGBColor(184, 187, 38),
                negative: RGBColor(204, 36, 29),
                warning: RGBColor(250, 189, 47)
            )
        case .cyberpunkNeon:
            return AppTheme(
                id: name,
                displayName: "Cyberpunk Neon",
                background: RGBColor(10, 10, 10),
                backgroundDark: RGBColor(3, 3, 6),
                foreground: RGBColor(238, 245, 255),
                accent: RGBColor(0, 245, 255),
                accentSecondary: RGBColor(176, 38, 255),
                positive: RGBColor(0, 245, 255),
                negative: RGBColor(255, 0, 128),
                warning: RGBColor(255, 196, 0)
            )
        }
    }
}

// MARK: - Configuration
enum FloatingWidgetMode: String, Codable {
    case bitcoin
    case marquee
}

enum DataProvider: String, Codable, CaseIterable {
    case kuCoin
    case binance
    case coinGecko

    var displayName: String {
        switch self {
        case .kuCoin: return "KuCoin"
        case .binance: return "Binance"
        case .coinGecko: return "CoinGecko"
        }
    }

    var quoteLabel: String {
        switch self {
        case .coinGecko: return "USD"
        case .kuCoin, .binance: return "USDT"
        }
    }
}

struct AppConfig: Codable {
    var cryptos: [String]
    var transparency: Double
    var windowX: Double
    var windowY: Double
    var isExpanded: Bool
    var refreshRate: Int
    var showSparklines: Bool
    var menuBarSymbol: String?
    var floatingWidgetMode: FloatingWidgetMode
    var theme: AppThemeName
    var dataProvider: DataProvider

    static let `default` = AppConfig(
        cryptos: ["BTC", "ETH", "SOL"],
        transparency: 0.85,
        windowX: 100,
        windowY: 100,
        isExpanded: true,
        refreshRate: 30,
        showSparklines: true,
        menuBarSymbol: nil,
        floatingWidgetMode: .bitcoin,
        theme: .cryptoFloat,
        dataProvider: .kuCoin
    )

    static let configPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".cryptofloat_config.json")

    static func load() -> AppConfig {
        guard let data = try? Data(contentsOf: configPath),
              let config = try? JSONDecoder().decode(AppConfig.self, from: data) else {
            return .default
        }
        return config
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(self) else { return }
        try? data.write(to: AppConfig.configPath)
    }
}

// Tolerant decoding: a missing or malformed key falls back to its default
// instead of throwing away the entire saved configuration. This keeps older
// config files (and future schema changes) working seamlessly.
extension AppConfig {
    enum CodingKeys: String, CodingKey {
        case cryptos, transparency, windowX, windowY, isExpanded, refreshRate, showSparklines, menuBarSymbol, floatingWidgetMode, theme, dataProvider
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppConfig.default
        cryptos        = (try? c.decode([String].self, forKey: .cryptos)) ?? d.cryptos
        transparency   = (try? c.decode(Double.self,   forKey: .transparency)) ?? d.transparency
        windowX        = (try? c.decode(Double.self,   forKey: .windowX)) ?? d.windowX
        windowY        = (try? c.decode(Double.self,   forKey: .windowY)) ?? d.windowY
        isExpanded     = (try? c.decode(Bool.self,     forKey: .isExpanded)) ?? d.isExpanded
        refreshRate    = (try? c.decode(Int.self,      forKey: .refreshRate)) ?? d.refreshRate
        showSparklines = (try? c.decode(Bool.self,     forKey: .showSparklines)) ?? d.showSparklines
        menuBarSymbol  = try? c.decode(String.self,    forKey: .menuBarSymbol)
        floatingWidgetMode = (try? c.decode(FloatingWidgetMode.self, forKey: .floatingWidgetMode)) ?? d.floatingWidgetMode
        theme          = (try? c.decode(AppThemeName.self, forKey: .theme)) ?? d.theme
        dataProvider   = (try? c.decode(DataProvider.self, forKey: .dataProvider)) ?? d.dataProvider
    }
}

// MARK: - Price Formatter
class PriceFormatter {
    static let shared = PriceFormatter()

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private let smallPriceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.minimumFractionDigits = 4
        formatter.maximumFractionDigits = 6
        return formatter
    }()

    private let groupedFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter
    }()

    func format(_ price: Double) -> String {
        if price >= 1 {
            // Normal prices: $90,719.00, $3,097.70, $136.42
            return currencyFormatter.string(from: NSNumber(value: price)) ?? "$0.00"
        } else if price >= 0.0001 {
            // Small prices: $0.0012
            return smallPriceFormatter.string(from: NSNumber(value: price)) ?? "$0.0000"
        } else {
            // Very small prices: more decimals
            return String(format: "$%.8f", price)
        }
    }

    /// Compact form used in the menu bar where horizontal space is scarce.
    func compact(_ price: Double) -> String {
        if price >= 1000 {
            let rounded = NSNumber(value: price.rounded())
            return "$" + (groupedFormatter.string(from: rounded) ?? "0")
        } else if price >= 1 {
            return String(format: "$%.2f", price)
        }
        return format(price)
    }
}

// MARK: - Price Data
struct PriceData {
    let price: Double
    let change24h: Double
    let hasError: Bool
}

struct ChartPoint {
    let time: TimeInterval
    let price: Double
}

// MARK: - Market Data API Manager
class CryptoAPI {
    static let shared = CryptoAPI()
    private let kuCoinBaseURL = "https://api.kucoin.com"
    private let binanceBaseURL = "https://data-api.binance.vision"
    private let coinGeckoBaseURL = "https://api.coingecko.com/api/v3"

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
        return PriceData(price: 0, change24h: 0, hasError: true)
    }

    private func request(_ url: URL, completion: @escaping (Data?) -> Void) {
        var request = URLRequest(url: url)
        request.setValue("CryptoFloat/1.1", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            DispatchQueue.main.async { completion(data) }
        }.resume()
    }

    private func coinGeckoID(for symbol: String) -> String? {
        return coinGeckoIDs[symbol.uppercased()]
    }

    func fetchPrice(for symbol: String, provider: DataProvider, completion: @escaping (PriceData) -> Void) {
        switch provider {
        case .kuCoin:
            fetchKuCoinPrice(for: symbol, completion: completion)
        case .binance:
            fetchBinancePrice(for: symbol, completion: completion)
        case .coinGecko:
            fetchCoinGeckoPrice(for: symbol, completion: completion)
        }
    }

    private func fetchKuCoinPrice(for symbol: String, completion: @escaping (PriceData) -> Void) {
        let pair = "\(symbol.uppercased())-USDT"
        let urlString = "\(kuCoinBaseURL)/api/v1/market/stats?symbol=\(pair)"

        guard let url = URL(string: urlString) else {
            completion(errorPrice())
            return
        }

        request(url) { data in
            guard let data = data else {
                completion(self.errorPrice())
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let code = json["code"] as? String,
                   code == "200000",
                   let dataDict = json["data"] as? [String: Any] {

                    let priceStr = dataDict["last"] as? String ?? "0"
                    let price = Double(priceStr) ?? 0

                    let changeRateStr = dataDict["changeRate"] as? String ?? "0"
                    let changeRate = (Double(changeRateStr) ?? 0) * 100

                    completion(PriceData(price: price, change24h: changeRate, hasError: false))
                } else {
                    completion(self.errorPrice())
                }
            } catch {
                completion(self.errorPrice())
            }
        }
    }

    private func fetchBinancePrice(for symbol: String, completion: @escaping (PriceData) -> Void) {
        let pair = "\(symbol.uppercased())USDT"
        let urlString = "\(binanceBaseURL)/api/v3/ticker/24hr?symbol=\(pair)"

        guard let url = URL(string: urlString) else {
            completion(errorPrice())
            return
        }

        request(url) { data in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let priceString = json["lastPrice"] as? String,
                  let price = Double(priceString) else {
                completion(self.errorPrice())
                return
            }

            let changeString = json["priceChangePercent"] as? String ?? "0"
            let change = Double(changeString) ?? 0
            completion(PriceData(price: price, change24h: change, hasError: false))
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
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataDict = json[id] as? [String: Any],
                  let price = dataDict["usd"] as? Double else {
                completion(self.errorPrice())
                return
            }

            let change = dataDict["usd_24h_change"] as? Double ?? 0
            completion(PriceData(price: price, change24h: change, hasError: false))
        }
    }

    func fetchAllPrices(for symbols: [String], provider: DataProvider, completion: @escaping ([String: PriceData]) -> Void) {
        if provider == .coinGecko {
            fetchCoinGeckoAllPrices(for: symbols, completion: completion)
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
            completion(Dictionary(uniqueKeysWithValues: symbols.map { ($0, errorPrice()) }))
            return
        }

        var components = URLComponents(string: "\(coinGeckoBaseURL)/simple/price")
        components?.queryItems = [
            URLQueryItem(name: "ids", value: pairs.map { $0.id }.joined(separator: ",")),
            URLQueryItem(name: "vs_currencies", value: "usd"),
            URLQueryItem(name: "include_24hr_change", value: "true")
        ]

        guard let url = components?.url else {
            completion(Dictionary(uniqueKeysWithValues: symbols.map { ($0, errorPrice()) }))
            return
        }

        request(url) { data in
            var results = Dictionary(uniqueKeysWithValues: symbols.map { ($0, self.errorPrice()) })

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(results)
                return
            }

            for pair in pairs {
                guard let dataDict = json[pair.id] as? [String: Any],
                      let price = dataDict["usd"] as? Double else {
                    continue
                }
                let change = dataDict["usd_24h_change"] as? Double ?? 0
                results[pair.symbol] = PriceData(price: price, change24h: change, hasError: false)
            }

            completion(results)
        }
    }

    /// Fetches ~24h of hourly closing prices for a tiny trend sparkline.
    /// Returns an empty array on any failure so the UI can simply skip drawing.
    func fetchSparkline(for symbol: String, provider: DataProvider, completion: @escaping ([Double]) -> Void) {
        switch provider {
        case .kuCoin:
            fetchKuCoinSparkline(for: symbol, completion: completion)
        case .binance:
            fetchBinanceSparkline(for: symbol, completion: completion)
        case .coinGecko:
            fetchCoinGeckoSparkline(for: symbol, completion: completion)
        }
    }

    private func fetchKuCoinSparkline(for symbol: String, completion: @escaping ([Double]) -> Void) {
        let pair = "\(symbol.uppercased())-USDT"
        let end = Int(Date().timeIntervalSince1970)
        let start = end - 60 * 60 * 26  // 26h window to comfortably capture 24 hourly candles
        let urlString = "\(kuCoinBaseURL)/api/v1/market/candles?type=1hour&symbol=\(pair)&startAt=\(start)&endAt=\(end)"

        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { completion([]) }
            return
        }

        request(url) { data in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let code = json["code"] as? String, code == "200000",
                  let rows = json["data"] as? [[Any]] else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            // Each candle: [time, open, close, high, low, volume, turnover], newest first.
            let closesNewestFirst: [Double] = rows.compactMap { row in
                guard row.count > 2, let s = row[2] as? String, let v = Double(s) else { return nil }
                return v
            }
            let chronological = Array(closesNewestFirst.reversed())
            let trimmed = Array(chronological.suffix(32))

            completion(trimmed)
        }
    }

    private func fetchBinanceSparkline(for symbol: String, completion: @escaping ([Double]) -> Void) {
        let pair = "\(symbol.uppercased())USDT"
        let urlString = "\(binanceBaseURL)/api/v3/klines?symbol=\(pair)&interval=1h&limit=32"

        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { completion([]) }
            return
        }

        request(url) { data in
            guard let data = data,
                  let rows = try? JSONSerialization.jsonObject(with: data) as? [[Any]] else {
                completion([])
                return
            }

            let values = rows.compactMap { row -> Double? in
                guard row.count > 4, let close = row[4] as? String else { return nil }
                return Double(close)
            }
            completion(Array(values.suffix(32)))
        }
    }

    private func fetchCoinGeckoSparkline(for symbol: String, completion: @escaping ([Double]) -> Void) {
        fetchCoinGeckoMarketChart(for: symbol, days: 1) { points in
            completion(Array(points.map { $0.price }.suffix(32)))
        }
    }

    /// Fetches 7 days of two-hour closing prices for the detail popup chart.
    /// Returns an empty array on any failure so the popup can show a soft error state.
    func fetchSevenDayChart(for symbol: String, provider: DataProvider, completion: @escaping ([ChartPoint]) -> Void) {
        switch provider {
        case .kuCoin:
            fetchKuCoinSevenDayChart(for: symbol, completion: completion)
        case .binance:
            fetchBinanceSevenDayChart(for: symbol, completion: completion)
        case .coinGecko:
            fetchCoinGeckoMarketChart(for: symbol, days: 7) { points in
                completion(Array(points.suffix(90)))
            }
        }
    }

    private func fetchKuCoinSevenDayChart(for symbol: String, completion: @escaping ([ChartPoint]) -> Void) {
        let pair = "\(symbol.uppercased())-USDT"
        let end = Int(Date().timeIntervalSince1970)
        let start = end - 60 * 60 * 24 * 7
        let urlString = "\(kuCoinBaseURL)/api/v1/market/candles?type=2hour&symbol=\(pair)&startAt=\(start)&endAt=\(end)"

        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { completion([]) }
            return
        }

        request(url) { data in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let code = json["code"] as? String, code == "200000",
                  let rows = json["data"] as? [[Any]] else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            // Each candle: [time, open, close, high, low, volume, turnover], newest first.
            let pointsNewestFirst: [ChartPoint] = rows.compactMap { row in
                guard row.count > 2,
                      let priceString = row[2] as? String,
                      let price = Double(priceString) else {
                    return nil
                }

                let time: TimeInterval?
                if let timeString = row[0] as? String {
                    time = TimeInterval(timeString)
                } else if let timeNumber = row[0] as? NSNumber {
                    time = timeNumber.doubleValue
                } else {
                    time = nil
                }

                guard let time = time else { return nil }
                return ChartPoint(time: time, price: price)
            }
            let chronological = Array(pointsNewestFirst.reversed())
            let trimmed = Array(chronological.suffix(90))

            completion(trimmed)
        }
    }

    private func fetchBinanceSevenDayChart(for symbol: String, completion: @escaping ([ChartPoint]) -> Void) {
        let pair = "\(symbol.uppercased())USDT"
        let urlString = "\(binanceBaseURL)/api/v3/klines?symbol=\(pair)&interval=2h&limit=84"

        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { completion([]) }
            return
        }

        request(url) { data in
            guard let data = data,
                  let rows = try? JSONSerialization.jsonObject(with: data) as? [[Any]] else {
                completion([])
                return
            }

            let points: [ChartPoint] = rows.compactMap { row in
                guard row.count > 4,
                      let timeMS = row[0] as? NSNumber,
                      let close = row[4] as? String,
                      let price = Double(close) else {
                    return nil
                }
                return ChartPoint(time: timeMS.doubleValue / 1000.0, price: price)
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
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let rows = json["prices"] as? [[Any]] else {
                completion([])
                return
            }

            let points: [ChartPoint] = rows.compactMap { row in
                guard row.count > 1,
                      let timeMS = row[0] as? NSNumber,
                      let priceNumber = row[1] as? NSNumber else {
                    return nil
                }
                return ChartPoint(time: timeMS.doubleValue / 1000.0, price: priceNumber.doubleValue)
            }

            completion(points)
        }
    }
}

// MARK: - Toggle Button View
class ToggleButtonView: NSView {
    var isHovered = false
    var isExpanded = true
    var onClick: (() -> Void)?
    var backgroundOpacity: CGFloat = 0.85 {
        didSet { needsDisplay = true }
    }

    /// 24h change of the primary coin; tints the ring green/red as an ambient signal.
    var accentChange: Double = 0 {
        didSet { needsDisplay = true }
    }

    private var trackingArea: NSTrackingArea?

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        setupTrackingArea()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupTrackingArea()
    }

    private func setupTrackingArea() {
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    private func accentRingColor() -> NSColor {
        let strong: CGFloat = isHovered ? 0.9 : 0.6
        let theme = ThemeCatalog.current
        if accentChange > 0.05 {
            return theme.positive.color(alpha: strong)
        } else if accentChange < -0.05 {
            return theme.negative.color(alpha: strong)
        } else {
            return theme.accent.color(alpha: isHovered ? 0.85 : 0.45)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let circleRect = bounds.insetBy(dx: 3, dy: 3)
        let path = NSBezierPath(ovalIn: circleRect)

        // Soft outer glow on hover
        if isHovered {
            let glow = NSBezierPath(ovalIn: bounds.insetBy(dx: 0.5, dy: 0.5))
            ThemeCatalog.current.accent.color(alpha: 0.18 * backgroundOpacity).setStroke()
            glow.lineWidth = 3
            glow.stroke()
        }

        // Vertical gradient fill for depth
        let top: NSColor
        let bottom: NSColor
        let theme = ThemeCatalog.current
        if isHovered {
            top = theme.accent.color(alpha: 0.30 * backgroundOpacity)
            bottom = theme.background.color(alpha: 0.97 * backgroundOpacity)
        } else {
            top = theme.background.color(alpha: 0.92 * backgroundOpacity)
            bottom = theme.backgroundDark.color(alpha: 0.92 * backgroundOpacity)
        }
        if let gradient = NSGradient(starting: top, ending: bottom) {
            gradient.draw(in: path, angle: -90)
        } else {
            bottom.setFill()
            path.fill()
        }

        // Accent ring (reflects market direction)
        let ringColor = accentRingColor()
        ringColor.withAlphaComponent(ringColor.alphaComponent * backgroundOpacity).setStroke()
        path.lineWidth = isHovered ? 2 : 1.5
        path.stroke()

        // ₿ glyph with a subtle shadow
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.45)
        shadow.shadowBlurRadius = 2
        shadow.shadowOffset = NSSize(width: 0, height: -1)

        let symbol = "₿"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 19, weight: .semibold),
            .foregroundColor: ThemeCatalog.current.foreground.color(),
            .shadow: shadow
        ]
        let size = symbol.size(withAttributes: attributes)
        let point = NSPoint(
            x: (bounds.width - size.width) / 2,
            y: (bounds.height - size.height) / 2
        )
        symbol.draw(at: point, withAttributes: attributes)
    }

    private func pulse() {
        guard let layer = self.layer else { return }
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [1.0, 0.86, 1.0]
        animation.keyTimes = [0.0, 0.4, 1.0]
        animation.duration = 0.22
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        layer.add(animation, forKey: "pulse")
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        if bounds.contains(location) {
            pulse()
            onClick?()
        }
    }
}

// MARK: - Marquee Widget View
class MarqueeWidgetView: NSView {
    var onClick: (() -> Void)?
    var backgroundOpacity: CGFloat = 0.85 {
        didSet { needsDisplay = true }
    }
    var accentChange: Double = 0 {
        didSet { needsDisplay = true }
    }

    private var symbols: [String] = []
    private var prices: [String: PriceData] = [:]
    private var isHovered = false
    private var scrollOffset: CGFloat = 0
    private var scrollTimer: Timer?
    private var trackingArea: NSTrackingArea?

    private let sidePadding: CGFloat = 14
    private let itemGap: CGFloat = 28

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit {
        scrollTimer?.invalidate()
    }

    private func setup() {
        wantsLayer = true
        setupTrackingArea()
        startScrolling()
    }

    override var mouseDownCanMoveWindow: Bool { true }

    private func setupTrackingArea() {
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }

        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        trackingArea = area
        addTrackingArea(area)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        setupTrackingArea()
    }

    func setMarketData(symbols: [String], prices: [String: PriceData]) {
        self.symbols = symbols
        self.prices = prices
        needsDisplay = true
    }

    private func startScrolling() {
        scrollTimer?.invalidate()
        scrollTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.scrollOffset += self.isHovered ? 0.35 : 0.75
            let cycle = max(self.marqueeWidth(), 1)
            if self.scrollOffset > cycle {
                self.scrollOffset -= cycle
            }
            self.needsDisplay = true
        }
    }

    private func accentColor(alpha: CGFloat = 1) -> NSColor {
        let theme = ThemeCatalog.current
        if accentChange > 0.05 {
            return theme.positive.color(alpha: alpha)
        } else if accentChange < -0.05 {
            return theme.negative.color(alpha: alpha)
        }
        return theme.accent.color(alpha: alpha)
    }

    private func attributes(font: NSFont, color: NSColor) -> [NSAttributedString.Key: Any] {
        return [
            .font: font,
            .foregroundColor: color
        ]
    }

    private var symbolAttrs: [NSAttributedString.Key: Any] {
        attributes(font: NSFont.systemFont(ofSize: 13, weight: .bold), color: ThemeCatalog.current.foreground.color())
    }

    private var priceAttrs: [NSAttributedString.Key: Any] {
        attributes(
            font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
            color: ThemeCatalog.current.foreground.color(alpha: 0.86)
        )
    }

    private var loadingAttrs: [NSAttributedString.Key: Any] {
        attributes(
            font: NSFont.systemFont(ofSize: 12, weight: .medium),
            color: ThemeCatalog.current.foreground.color(alpha: 0.58)
        )
    }

    private func changeAttrs(for change: Double) -> [NSAttributedString.Key: Any] {
        let color = change >= 0
            ? ThemeCatalog.current.positive.color()
            : ThemeCatalog.current.negative.color()
        return attributes(font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium), color: color)
    }

    private func measuredTextWidth(_ text: String, attrs: [NSAttributedString.Key: Any]) -> CGFloat {
        return ceil(text.size(withAttributes: attrs).width)
    }

    private func itemWidth(for symbol: String) -> CGFloat {
        guard let data = prices[symbol], !data.hasError, data.price > 0 else {
            return measuredTextWidth(symbol, attrs: symbolAttrs)
                + 6
                + measuredTextWidth("Loading", attrs: loadingAttrs)
        }

        let priceText = PriceFormatter.shared.compact(data.price)
        let changeText = String(format: "%@%.2f%%", data.change24h >= 0 ? "+" : "", data.change24h)
        return measuredTextWidth(symbol, attrs: symbolAttrs)
            + 8
            + measuredTextWidth(priceText, attrs: priceAttrs)
            + 8
            + measuredTextWidth(changeText, attrs: changeAttrs(for: data.change24h))
    }

    private func marqueeWidth() -> CGFloat {
        let activeSymbols = symbols.isEmpty ? ["BTC"] : symbols
        let width = activeSymbols.reduce(CGFloat(0)) { partial, symbol in
            partial + itemWidth(for: symbol) + itemGap
        }
        return max(width, bounds.width - sidePadding * 2)
    }

    private func drawItems(startingAt startX: CGFloat, baselineY: CGFloat) {
        let activeSymbols = symbols.isEmpty ? ["BTC"] : symbols
        var x = startX

        for symbol in activeSymbols {
            symbol.draw(at: NSPoint(x: x, y: baselineY), withAttributes: symbolAttrs)
            x += measuredTextWidth(symbol, attrs: symbolAttrs) + 8

            if let data = prices[symbol], !data.hasError, data.price > 0 {
                let priceText = PriceFormatter.shared.compact(data.price)
                priceText.draw(at: NSPoint(x: x, y: baselineY), withAttributes: priceAttrs)
                x += measuredTextWidth(priceText, attrs: priceAttrs) + 8

                let changeText = String(format: "%@%.2f%%", data.change24h >= 0 ? "+" : "", data.change24h)
                changeText.draw(at: NSPoint(x: x, y: baselineY), withAttributes: changeAttrs(for: data.change24h))
                x += measuredTextWidth(changeText, attrs: changeAttrs(for: data.change24h))
            } else {
                "Loading".draw(at: NSPoint(x: x, y: baselineY), withAttributes: loadingAttrs)
                x += measuredTextWidth("Loading", attrs: loadingAttrs)
            }

            let dotAttrs = attributes(
                font: NSFont.systemFont(ofSize: 10, weight: .semibold),
                color: ThemeCatalog.current.foreground.color(alpha: 0.25)
            )
            let dotX = x + itemGap / 2 - 2
            "•".draw(at: NSPoint(x: dotX, y: baselineY + 1), withAttributes: dotAttrs)
            x += itemGap
        }
    }

    private func pulse() {
        guard let layer = self.layer else { return }
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [1.0, 0.97, 1.0]
        animation.keyTimes = [0.0, 0.4, 1.0]
        animation.duration = 0.18
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        layer.add(animation, forKey: "pulse")
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        if bounds.contains(location) {
            pulse()
            onClick?()
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let rect = bounds.insetBy(dx: 2, dy: 3)
        let background = NSBezierPath(roundedRect: rect, xRadius: rect.height / 2, yRadius: rect.height / 2)
        let theme = ThemeCatalog.current

        let top = isHovered
            ? theme.accent.color(alpha: 0.22 * backgroundOpacity)
            : theme.background.color(alpha: 0.94 * backgroundOpacity)
        let bottom = isHovered
            ? theme.background.color(alpha: 0.96 * backgroundOpacity)
            : theme.backgroundDark.color(alpha: 0.94 * backgroundOpacity)

        if let gradient = NSGradient(starting: top, ending: bottom) {
            gradient.draw(in: background, angle: -90)
        } else {
            bottom.setFill()
            background.fill()
        }

        accentColor(alpha: (isHovered ? 0.30 : 0.18) * backgroundOpacity).setStroke()
        background.lineWidth = 1
        background.stroke()

        NSGraphicsContext.saveGraphicsState()
        background.addClip()

        let baselineY = (bounds.height - 15) / 2
        let cycle = marqueeWidth()
        let startX = sidePadding - scrollOffset
        drawItems(startingAt: startX, baselineY: baselineY)
        drawItems(startingAt: startX + cycle, baselineY: baselineY)
        if startX + cycle < bounds.width {
            drawItems(startingAt: startX + cycle * 2, baselineY: baselineY)
        }

        let leftFade = NSBezierPath(rect: NSRect(x: rect.minX, y: rect.minY + 2, width: 22, height: rect.height - 4))
        if let gradient = NSGradient(
            starting: theme.background.color(alpha: 0.72 * backgroundOpacity),
            ending: theme.background.color(alpha: 0)
        ) {
            gradient.draw(in: leftFade, angle: 0)
        }

        let rightFade = NSBezierPath(rect: NSRect(x: rect.maxX - 22, y: rect.minY + 2, width: 22, height: rect.height - 4))
        if let gradient = NSGradient(
            starting: theme.background.color(alpha: 0),
            ending: theme.background.color(alpha: 0.72 * backgroundOpacity)
        ) {
            gradient.draw(in: rightFade, angle: 0)
        }

        NSGraphicsContext.restoreGraphicsState()
    }
}

// MARK: - Glass Content View
class GlassContentView: NSView {
    private let cornerRadius: CGFloat = 22
    var backgroundOpacity: CGFloat = 0.85 {
        didSet { needsDisplay = true }
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        updateCornerMask()
    }

    override func layout() {
        super.layout()
        updateCornerMask()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateCornerMask()
    }

    private func updateCornerMask() {
        guard let layer = layer else { return }
        layer.cornerRadius = cornerRadius
        if #available(macOS 10.15, *) {
            layer.cornerCurve = .continuous
        }
        layer.masksToBounds = true

        let mask = CAShapeLayer()
        mask.frame = bounds
        mask.path = CGPath(
            roundedRect: bounds,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
        layer.mask = mask
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let fillPath = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)
        let theme = ThemeCatalog.current
        theme.background.color(alpha: 0.72 * backgroundOpacity).setFill()
        fillPath.fill()

        // Faint inner highlight along the top edge for a glassy sheen
        let highlight = NSBezierPath()
        highlight.move(to: NSPoint(x: cornerRadius, y: bounds.height - 1))
        highlight.line(to: NSPoint(x: bounds.width - cornerRadius, y: bounds.height - 1))
        theme.foreground.color(alpha: 0.12 * backgroundOpacity).setStroke()
        highlight.lineWidth = 1
        highlight.stroke()

        let strokeRect = bounds.insetBy(dx: 0.75, dy: 0.75)
        let path = NSBezierPath(
            roundedRect: strokeRect,
            xRadius: max(cornerRadius - 0.75, 0),
            yRadius: max(cornerRadius - 0.75, 0)
        )
        theme.accent.color(alpha: 0.3 * backgroundOpacity).setStroke()
        path.lineWidth = 1.5
        path.stroke()
    }
}

// MARK: - Sparkline View
class SparklineView: NSView {
    private var values: [Double] = []

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    func setValues(_ values: [Double]) {
        self.values = values
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard values.count >= 2, bounds.width > 1, bounds.height > 1 else { return }

        let minV = values.min() ?? 0
        let maxV = values.max() ?? 0
        let range = maxV - minV
        let inset: CGFloat = 3
        let stepX = bounds.width / CGFloat(values.count - 1)

        func point(_ i: Int) -> NSPoint {
            let x = CGFloat(i) * stepX
            let norm: CGFloat = range > 0 ? CGFloat((values[i] - minV) / range) : 0.5
            let y = inset + norm * (bounds.height - 2 * inset)
            return NSPoint(x: x, y: y)
        }

        let isUp = (values.last ?? 0) >= (values.first ?? 0)
        let lineColor = isUp
            ? ThemeCatalog.current.positive.color(alpha: 0.95)
            : ThemeCatalog.current.negative.color(alpha: 0.95)

        // Gradient fill beneath the line
        let fillPath = NSBezierPath()
        fillPath.move(to: NSPoint(x: 0, y: 0))
        for i in 0..<values.count {
            fillPath.line(to: point(i))
        }
        fillPath.line(to: NSPoint(x: bounds.width, y: 0))
        fillPath.close()
        if let gradient = NSGradient(starting: lineColor.withAlphaComponent(0.0),
                                     ending: lineColor.withAlphaComponent(0.28)) {
            gradient.draw(in: fillPath, angle: 90)
        }

        // The trend line itself
        let linePath = NSBezierPath()
        linePath.lineJoinStyle = .round
        linePath.lineCapStyle = .round
        for i in 0..<values.count {
            if i == 0 { linePath.move(to: point(i)) } else { linePath.line(to: point(i)) }
        }
        lineColor.setStroke()
        linePath.lineWidth = 1.6
        linePath.stroke()

        // End dot to anchor the eye on the latest value
        let last = point(values.count - 1)
        let dot = NSBezierPath(ovalIn: NSRect(x: last.x - 2, y: last.y - 2, width: 4, height: 4))
        lineColor.setFill()
        dot.fill()
    }
}

// MARK: - Seven Day Chart Popup
class SevenDayChartContentView: NSView {
    private let symbol: String
    private let cornerRadius: CGFloat = 22
    var backgroundOpacity: CGFloat = 0.85 {
        didSet { needsDisplay = true }
    }

    private var points: [ChartPoint] = []
    private var isLoading = true
    private var hasError = false
    private var latestPrice: Double?
    private var change24h: Double?
    private var hoveredIndex: Int?
    private var trackingArea: NSTrackingArea?

    private lazy var hoverDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d HH:mm"
        return f
    }()

    init(frame: NSRect, symbol: String, latest: PriceData?) {
        self.symbol = symbol
        if let latest = latest, !latest.hasError {
            self.latestPrice = latest.price
            self.change24h = latest.change24h
        }
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func setup() {
        wantsLayer = false
        setupTrackingArea()
    }

    override func layout() {
        super.layout()
        updateCornerMask()
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        updateCornerMask()
    }

    private func updateCornerMask() {
        guard let layer = layer else { return }
        layer.cornerRadius = cornerRadius
        if #available(macOS 10.15, *) {
            layer.cornerCurve = .continuous
        }
        layer.masksToBounds = true

        let mask = CAShapeLayer()
        mask.frame = bounds
        mask.path = CGPath(
            roundedRect: bounds,
            cornerWidth: cornerRadius,
            cornerHeight: cornerRadius,
            transform: nil
        )
        layer.mask = mask
    }

    private func setupTrackingArea() {
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }

        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        trackingArea = area
        addTrackingArea(area)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        setupTrackingArea()
    }

    func setSummary(_ data: PriceData?) {
        guard let data = data, !data.hasError else { return }
        latestPrice = data.price
        change24h = data.change24h
        needsDisplay = true
    }

    func setPoints(_ points: [ChartPoint]) {
        self.points = points
        hoveredIndex = nil
        isLoading = false
        hasError = points.count < 2
        needsDisplay = true
    }

    private func attributes(font: NSFont, color: NSColor, alignment: NSTextAlignment = .left) -> [NSAttributedString.Key: Any] {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        return [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: style
        ]
    }

    private func sevenDayChange() -> Double? {
        guard points.count >= 2,
              let first = points.first?.price,
              first != 0,
              let last = points.last?.price else {
            return nil
        }
        return ((last - first) / first) * 100
    }

    private func chartRect() -> NSRect {
        return NSRect(x: 18, y: 28, width: bounds.width - 36, height: 104)
    }

    private func updateHover(at location: NSPoint?) {
        guard points.count >= 2, let location = location, chartRect().contains(location) else {
            if hoveredIndex != nil {
                hoveredIndex = nil
                needsDisplay = true
            }
            return
        }

        let rect = chartRect()
        let clampedX = min(max(location.x, rect.minX), rect.maxX)
        let ratio = (clampedX - rect.minX) / rect.width
        let index = Int(round(ratio * CGFloat(points.count - 1)))
        let clampedIndex = min(max(index, 0), points.count - 1)

        if hoveredIndex != clampedIndex {
            hoveredIndex = clampedIndex
            needsDisplay = true
        }
    }

    override func mouseMoved(with event: NSEvent) {
        updateHover(at: convert(event.locationInWindow, from: nil))
    }

    override func mouseExited(with event: NSEvent) {
        updateHover(at: nil)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let fillPath = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)
        let theme = ThemeCatalog.current
        theme.backgroundDark.color(alpha: 0.94 * backgroundOpacity).setFill()
        fillPath.fill()

        let strokeRect = bounds.insetBy(dx: 0.75, dy: 0.75)
        let strokePath = NSBezierPath(
            roundedRect: strokeRect,
            xRadius: max(cornerRadius - 0.75, 0),
            yRadius: max(cornerRadius - 0.75, 0)
        )
        theme.accent.color(alpha: 0.36 * backgroundOpacity).setStroke()
        strokePath.lineWidth = 1.5
        strokePath.stroke()

        let titleAttrs = attributes(
            font: NSFont.systemFont(ofSize: 14, weight: .semibold),
            color: theme.foreground.color()
        )
        "\(symbol)/USDT".draw(at: NSPoint(x: 18, y: bounds.height - 33), withAttributes: titleAttrs)

        let tagAttrs = attributes(
            font: NSFont.systemFont(ofSize: 10, weight: .semibold),
            color: theme.accent.color(alpha: 0.72),
            alignment: .right
        )
        "7D".draw(in: NSRect(x: bounds.width - 62, y: bounds.height - 31, width: 44, height: 14), withAttributes: tagAttrs)

        let hoveredPoint = hoveredIndex.flatMap { points.indices.contains($0) ? points[$0] : nil }
        let displayPrice = hoveredPoint?.price ?? latestPrice

        if let displayPrice = displayPrice {
            let priceAttrs = attributes(
                font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
                color: theme.foreground.color(alpha: 0.82)
            )
            PriceFormatter.shared.format(displayPrice).draw(
                at: NSPoint(x: 18, y: bounds.height - 54),
                withAttributes: priceAttrs
            )
        }

        if let hoveredPoint = hoveredPoint {
            let dateAttrs = attributes(
                font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular),
                color: theme.accent.color(alpha: 0.72),
                alignment: .right
            )
            hoverDateFormatter.string(from: Date(timeIntervalSince1970: hoveredPoint.time)).draw(
                in: NSRect(x: bounds.width - 122, y: bounds.height - 54, width: 104, height: 14),
                withAttributes: dateAttrs
            )
        } else if let change = sevenDayChange() ?? change24h {
            let isUp = change >= 0
            let color = isUp
                ? theme.positive.color(alpha: 0.95)
                : theme.negative.color(alpha: 0.95)
            let changeAttrs = attributes(
                font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
                color: color,
                alignment: .right
            )
            let text = String(format: "%@%.2f%%", isUp ? "+" : "", change)
            text.draw(in: NSRect(x: bounds.width - 100, y: bounds.height - 54, width: 82, height: 16), withAttributes: changeAttrs)
        }

        drawChart(in: chartRect())
    }

    private func drawChart(in rect: NSRect) {
        let theme = ThemeCatalog.current
        let gridColor = theme.foreground.color(alpha: 0.08)
        for i in 0...3 {
            let y = rect.minY + rect.height * CGFloat(i) / 3.0
            let line = NSBezierPath()
            line.move(to: NSPoint(x: rect.minX, y: y))
            line.line(to: NSPoint(x: rect.maxX, y: y))
            gridColor.setStroke()
            line.lineWidth = 0.6
            line.stroke()
        }

        guard points.count >= 2, !hasError else {
            let text = isLoading ? "Loading chart..." : "Chart unavailable"
            let attrs = attributes(
                font: NSFont.systemFont(ofSize: 12, weight: .regular),
                color: theme.foreground.color(alpha: 0.52),
                alignment: .center
            )
            text.draw(in: NSRect(x: rect.minX, y: rect.midY - 8, width: rect.width, height: 18), withAttributes: attrs)
            return
        }

        let values = points.map { $0.price }
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 0
        let range = max(maxV - minV, 0.00000001)
        let inset: CGFloat = 7
        let stepX = rect.width / CGFloat(values.count - 1)

        func point(_ i: Int) -> NSPoint {
            let x = rect.minX + CGFloat(i) * stepX
            let norm = CGFloat((values[i] - minV) / range)
            let y = rect.minY + inset + norm * (rect.height - 2 * inset)
            return NSPoint(x: x, y: y)
        }

        let isUp = (values.last ?? 0) >= (values.first ?? 0)
        let lineColor = isUp
            ? theme.positive.color(alpha: 0.98)
            : theme.negative.color(alpha: 0.98)

        let fillPath = NSBezierPath()
        fillPath.move(to: NSPoint(x: rect.minX, y: rect.minY))
        for i in 0..<values.count {
            fillPath.line(to: point(i))
        }
        fillPath.line(to: NSPoint(x: rect.maxX, y: rect.minY))
        fillPath.close()
        if let gradient = NSGradient(
            starting: lineColor.withAlphaComponent(0.02),
            ending: lineColor.withAlphaComponent(0.26)
        ) {
            gradient.draw(in: fillPath, angle: 90)
        }

        let linePath = NSBezierPath()
        linePath.lineJoinStyle = .round
        linePath.lineCapStyle = .round
        for i in 0..<values.count {
            if i == 0 {
                linePath.move(to: point(i))
            } else {
                linePath.line(to: point(i))
            }
        }
        lineColor.setStroke()
        linePath.lineWidth = 2
        linePath.stroke()

        let last = point(values.count - 1)
        let dot = NSBezierPath(ovalIn: NSRect(x: last.x - 3, y: last.y - 3, width: 6, height: 6))
        lineColor.setFill()
        dot.fill()

        if let hoveredIndex = hoveredIndex, values.indices.contains(hoveredIndex) {
            let hovered = point(hoveredIndex)

            let guide = NSBezierPath()
            guide.move(to: NSPoint(x: hovered.x, y: rect.minY))
            guide.line(to: NSPoint(x: hovered.x, y: rect.maxY))
            theme.foreground.color(alpha: 0.22).setStroke()
            guide.lineWidth = 1
            guide.stroke()

            let ring = NSBezierPath(ovalIn: NSRect(x: hovered.x - 4, y: hovered.y - 4, width: 8, height: 8))
            theme.backgroundDark.color(alpha: 0.96).setFill()
            ring.fill()
            lineColor.setStroke()
            ring.lineWidth = 2
            ring.stroke()

            let tooltip = PriceFormatter.shared.format(values[hoveredIndex])
            let tooltipAttrs = attributes(
                font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium),
                color: theme.foreground.color(),
                alignment: .center
            )
            let textSize = tooltip.size(withAttributes: tooltipAttrs)
            let tooltipWidth = min(max(textSize.width + 14, 72), rect.width)
            let tooltipX = min(max(hovered.x - tooltipWidth / 2, rect.minX), rect.maxX - tooltipWidth)
            let tooltipY = min(hovered.y + 12, rect.maxY - 22)
            let tooltipRect = NSRect(x: tooltipX, y: tooltipY, width: tooltipWidth, height: 20)
            let tooltipPath = NSBezierPath(roundedRect: tooltipRect, xRadius: 7, yRadius: 7)
            theme.backgroundDark.color(alpha: 0.9).setFill()
            tooltipPath.fill()
            theme.foreground.color(alpha: 0.16).setStroke()
            tooltipPath.lineWidth = 1
            tooltipPath.stroke()
            tooltip.draw(in: tooltipRect.insetBy(dx: 4, dy: 3), withAttributes: tooltipAttrs)
        }

        let rangeAttrs = attributes(
            font: NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .regular),
            color: theme.foreground.color(alpha: 0.42),
            alignment: .right
        )
        PriceFormatter.shared.compact(maxV).draw(
            in: NSRect(x: rect.maxX - 76, y: rect.maxY - 14, width: 76, height: 12),
            withAttributes: rangeAttrs
        )
        PriceFormatter.shared.compact(minV).draw(
            in: NSRect(x: rect.maxX - 76, y: rect.minY + 2, width: 76, height: 12),
            withAttributes: rangeAttrs
        )
    }
}

// MARK: - Animated Price Label
class AnimatedPriceLabel: NSTextField {
    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.masksToBounds = false
    }

    func flashGreen() {
        flash(color: ThemeCatalog.current.positive.color(alpha: 0.8))
    }

    func flashRed() {
        flash(color: ThemeCatalog.current.negative.color(alpha: 0.8))
    }

    private func flash(color: NSColor) {
        guard let layer = self.layer else { return }

        let flash = CALayer()
        flash.frame = layer.bounds.insetBy(dx: -4, dy: -2)
        flash.cornerRadius = 4
        flash.backgroundColor = color.cgColor
        flash.opacity = 0

        layer.insertSublayer(flash, at: 0)

        CATransaction.begin()
        CATransaction.setCompletionBlock {
            flash.removeFromSuperlayer()
        }

        let animation = CAKeyframeAnimation(keyPath: "opacity")
        animation.values = [0.0, 0.7, 0.5, 0.0]
        animation.keyTimes = [0.0, 0.1, 0.5, 1.0]
        animation.duration = 0.6
        animation.isRemovedOnCompletion = true

        flash.add(animation, forKey: "flash")

        CATransaction.commit()
    }

    func animateValueChange(goingUp: Bool) {
        guard let layer = self.layer else { return }

        if goingUp {
            flashGreen()
        } else {
            flashRed()
        }

        let slideDistance: CGFloat = goingUp ? 3 : -3

        let slideAnimation = CAKeyframeAnimation(keyPath: "position.y")
        slideAnimation.values = [
            layer.position.y,
            layer.position.y + slideDistance,
            layer.position.y
        ]
        slideAnimation.keyTimes = [0.0, 0.3, 1.0]
        slideAnimation.duration = 0.3
        slideAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        layer.add(slideAnimation, forKey: "slide")

        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [1.0, 1.08, 1.0]
        scaleAnimation.keyTimes = [0.0, 0.2, 1.0]
        scaleAnimation.duration = 0.3
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)

        layer.add(scaleAnimation, forKey: "scale")
    }
}

// MARK: - Crypto Row View
class CryptoRowView: NSView {
    let symbol: String
    let showSparkline: Bool
    var onClick: ((CryptoRowView) -> Void)?

    private let symbolLabel = NSTextField(labelWithString: "")
    private let priceLabel = AnimatedPriceLabel(labelWithString: "Loading…")
    private let changeLabel = NSTextField(labelWithString: "")
    private let arrowLabel = NSTextField(labelWithString: "")
    private var sparklineView: SparklineView?

    private var lastPrice: Double = 0
    private var hasLoaded = false
    private var isHovered = false

    private var dimColor: NSColor {
        ThemeCatalog.current.foreground.color(alpha: 0.45)
    }

    init(frame: NSRect, symbol: String, showSparkline: Bool) {
        self.symbol = symbol
        self.showSparkline = showSparkline
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func makeLabel(_ field: NSTextField) {
        field.isBezeled = false
        field.drawsBackground = false
        field.isEditable = false
        field.isSelectable = false
    }

    private func setup() {
        wantsLayer = true
        let w = bounds.width

        makeLabel(symbolLabel)
        makeLabel(priceLabel)
        makeLabel(changeLabel)
        makeLabel(arrowLabel)

        symbolLabel.stringValue = symbol
        symbolLabel.textColor = ThemeCatalog.current.foreground.color()
        addSubview(symbolLabel)

        priceLabel.textColor = ThemeCatalog.current.foreground.color()
        priceLabel.alignment = .left
        addSubview(priceLabel)

        changeLabel.alignment = .right
        addSubview(changeLabel)

        arrowLabel.alignment = .center
        arrowLabel.wantsLayer = true

        if showSparkline {
            // Two-line layout: symbol + 24h% on top, price + arrow + sparkline below.
            symbolLabel.font = NSFont.boldSystemFont(ofSize: 14)
            symbolLabel.frame = NSRect(x: 14, y: 26, width: 90, height: 18)

            changeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
            changeLabel.frame = NSRect(x: w - 84, y: 27, width: 72, height: 16)

            priceLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
            priceLabel.frame = NSRect(x: 14, y: 6, width: 104, height: 18)

            arrowLabel.font = NSFont.systemFont(ofSize: 10, weight: .bold)
            arrowLabel.frame = NSRect(x: 118, y: 7, width: 14, height: 16)
            addSubview(arrowLabel)

            let spark = SparklineView(frame: NSRect(x: 140, y: 10, width: w - 152, height: 28))
            addSubview(spark)
            sparklineView = spark
        } else {
            // Compact single-line layout.
            symbolLabel.font = NSFont.boldSystemFont(ofSize: 14)
            symbolLabel.frame = NSRect(x: 14, y: 5, width: 56, height: 20)

            priceLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            priceLabel.frame = NSRect(x: 74, y: 5, width: 64, height: 20)

            changeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
            changeLabel.frame = NSRect(x: w - 76, y: 6, width: 64, height: 18)
        }

        let tracking = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(tracking)

        let click = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        click.numberOfClicksRequired = 1
        addGestureRecognizer(click)
    }

    func setSparkline(_ values: [Double]) {
        sparklineView?.setValues(values)
    }

    func update(price: Double, change: Double, hasError: Bool) {
        if hasError {
            if hasLoaded {
                // Keep the last known price, just dim it to signal staleness.
                priceLabel.textColor = dimColor
                changeLabel.textColor = dimColor
                arrowLabel.stringValue = ""
            } else {
                priceLabel.stringValue = "—"
                priceLabel.textColor = dimColor
                changeLabel.stringValue = ""
                arrowLabel.stringValue = ""
            }
            return
        }

        let priceWentUp = hasLoaded && price > lastPrice
        let priceWentDown = hasLoaded && price < lastPrice
        let priceChanged = hasLoaded && price != lastPrice

        priceLabel.stringValue = PriceFormatter.shared.format(price)
        priceLabel.textColor = ThemeCatalog.current.foreground.color()

        if priceChanged {
            if priceWentUp {
                arrowLabel.stringValue = "▲"
                arrowLabel.textColor = ThemeCatalog.current.positive.color()
                priceLabel.animateValueChange(goingUp: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.fadeOutArrow()
                }
            } else if priceWentDown {
                arrowLabel.stringValue = "▼"
                arrowLabel.textColor = ThemeCatalog.current.negative.color()
                priceLabel.animateValueChange(goingUp: false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.fadeOutArrow()
                }
            }
        }

        if change >= 0 {
            changeLabel.stringValue = String(format: "+%.2f%%", change)
            changeLabel.textColor = ThemeCatalog.current.positive.color()
        } else {
            changeLabel.stringValue = String(format: "%.2f%%", change)
            changeLabel.textColor = ThemeCatalog.current.negative.color()
        }

        lastPrice = price
        hasLoaded = true
    }

    private func fadeOutArrow() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.5
            arrowLabel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.arrowLabel.stringValue = ""
            self?.arrowLabel.alphaValue = 1
        })
    }

    @objc private func handleClick(_ sender: NSClickGestureRecognizer) {
        guard sender.state == .ended else { return }
        onClick?(self)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        needsDisplay = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if isHovered {
            let bg = NSBezierPath(roundedRect: bounds.insetBy(dx: 4, dy: 3), xRadius: 8, yRadius: 8)
            ThemeCatalog.current.foreground.color(alpha: 0.06).setFill()
            bg.fill()
        }

        let separator = NSBezierPath()
        separator.move(to: NSPoint(x: 12, y: 0.5))
        separator.line(to: NSPoint(x: bounds.width - 12, y: 0.5))
        ThemeCatalog.current.foreground.color(alpha: 0.07).setStroke()
        separator.lineWidth = 0.5
        separator.stroke()
    }
}

// MARK: - Floating Window
class FloatingWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless, .fullSizeContentView], backing: .buffered, defer: false)

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = true
        collectionBehavior = [.canJoinAllSpaces, .stationary]
    }

    override var canBecomeKey: Bool { true }
}

class ChartPopupWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless, .fullSizeContentView], backing: .buffered, defer: false)

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
    }

    override var canBecomeKey: Bool { true }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var floatingWindow: FloatingWindow!
    var config: AppConfig!
    var cryptoRows: [String: CryptoRowView] = [:]
    var updateTimer: Timer?
    var toggleButton: ToggleButtonView?
    var marqueeWidget: MarqueeWidgetView?
    var contentPanel: GlassContentView?
    var containerView: NSView!
    var chartWindow: ChartPopupWindow?
    var chartContentView: SevenDayChartContentView?
    var chartDismissalMonitors: [Any] = []
    var activeChartSymbol: String?

    var transparencyMenu: NSMenu!
    var refreshRateMenu: NSMenu!
    var removeMenu: NSMenu!
    var menuBarMenu: NSMenu!
    var floatingWidgetMenu: NSMenu!
    var themeMenu: NSMenu!
    var dataProviderMenu: NSMenu!
    var expandCollapseItem: NSMenuItem!
    var sparklineToggleItem: NSMenuItem!
    var updatedLabel: NSTextField?

    var latestPrices: [String: PriceData] = [:]
    var sparklineCache: [String: (values: [Double], fetchedAt: Date)] = [:]
    var chartCache: [String: (points: [ChartPoint], fetchedAt: Date)] = [:]

    let toggleButtonSize: CGFloat = 44
    let marqueeWidgetWidth: CGFloat = 274
    let panelWidth: CGFloat = 220
    let chartPopupSize = NSSize(width: 300, height: 190)
    let headerHeight: CGFloat = 30
    let padding: CGFloat = 12

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    let refreshRates: [(label: String, seconds: Int)] = [
        ("5 seconds", 5),
        ("10 seconds", 10),
        ("15 seconds", 15),
        ("30 seconds", 30),
        ("1 minute", 60),
        ("2 minutes", 120),
        ("5 minutes", 300)
    ]

    var rowHeight: CGFloat {
        return config.showSparklines ? 48 : 30
    }

    var panelContentHeight: CGFloat {
        return headerHeight + (rowHeight * CGFloat(config.cryptos.count)) + padding
    }

    var floatingWidgetWidth: CGFloat {
        return config.floatingWidgetMode == .marquee ? marqueeWidgetWidth : toggleButtonSize
    }

    var currentPanelWidth: CGFloat {
        return config.floatingWidgetMode == .marquee ? marqueeWidgetWidth : panelWidth
    }

    var expandedWidth: CGFloat {
        if config.floatingWidgetMode == .marquee {
            return max(floatingWidgetWidth, currentPanelWidth) + 10
        }
        return floatingWidgetWidth + 10 + currentPanelWidth + 5
    }

    var shouldUseWindowShadow: Bool {
        return config.floatingWidgetMode == .bitcoin
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        config = AppConfig.load()
        ThemeCatalog.current = ThemeCatalog.theme(for: config.theme)
        sanitizeMenuBarSymbol()

        setupStatusBar()
        setupWindow()
        startUpdateTimer()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hideChartPopup()
        let frame = floatingWindow.frame
        config.windowX = Double(frame.origin.x)
        config.windowY = Double(frame.origin.y)
        config.save()
    }

    private func sanitizeMenuBarSymbol() {
        if let sym = config.menuBarSymbol, !config.cryptos.contains(sym) {
            config.menuBarSymbol = nil
        }
    }

    // MARK: - Setup
    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "₿"
        statusItem.button?.font = NSFont.systemFont(ofSize: 14)

        let menu = NSMenu()

        let showItem = NSMenuItem(title: "Show/Hide Window", action: #selector(toggleWindowVisibility), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)

        expandCollapseItem = NSMenuItem(title: config.isExpanded ? "Collapse Prices" : "Expand Prices", action: #selector(toggleExpandedFromMenu), keyEquivalent: "")
        expandCollapseItem.target = self
        menu.addItem(expandCollapseItem)

        menu.addItem(NSMenuItem.separator())

        // Floating widget submenu
        floatingWidgetMenu = NSMenu()
        updateFloatingWidgetMenu()
        let floatingWidgetItem = NSMenuItem(title: "Floating Widget", action: nil, keyEquivalent: "")
        floatingWidgetItem.submenu = floatingWidgetMenu
        menu.addItem(floatingWidgetItem)

        // Theme submenu
        themeMenu = NSMenu()
        updateThemeMenu()
        let themeItem = NSMenuItem(title: "Theme", action: nil, keyEquivalent: "")
        themeItem.submenu = themeMenu
        menu.addItem(themeItem)

        // Data source submenu
        dataProviderMenu = NSMenu()
        updateDataProviderMenu()
        let dataProviderItem = NSMenuItem(title: "Data Source", action: nil, keyEquivalent: "")
        dataProviderItem.submenu = dataProviderMenu
        menu.addItem(dataProviderItem)

        // Transparency submenu
        transparencyMenu = NSMenu()
        for level in [100, 90, 80, 70, 60, 50] {
            let item = NSMenuItem(title: "\(level)%", action: #selector(setTransparency(_:)), keyEquivalent: "")
            item.target = self
            item.tag = level
            if Int(config.transparency * 100) == level {
                item.state = .on
            }
            transparencyMenu.addItem(item)
        }
        let transparencyItem = NSMenuItem(title: "Transparency", action: nil, keyEquivalent: "")
        transparencyItem.submenu = transparencyMenu
        menu.addItem(transparencyItem)

        // Refresh Rate submenu
        refreshRateMenu = NSMenu()
        for rate in refreshRates {
            let item = NSMenuItem(title: rate.label, action: #selector(setRefreshRate(_:)), keyEquivalent: "")
            item.target = self
            item.tag = rate.seconds
            if config.refreshRate == rate.seconds {
                item.state = .on
            }
            refreshRateMenu.addItem(item)
        }
        let refreshRateItem = NSMenuItem(title: "Refresh Rate", action: nil, keyEquivalent: "")
        refreshRateItem.submenu = refreshRateMenu
        menu.addItem(refreshRateItem)

        // Sparkline toggle
        sparklineToggleItem = NSMenuItem(title: "Show Sparklines", action: #selector(toggleSparklines(_:)), keyEquivalent: "")
        sparklineToggleItem.target = self
        sparklineToggleItem.state = config.showSparklines ? .on : .off
        menu.addItem(sparklineToggleItem)

        // Menu Bar Display submenu
        menuBarMenu = NSMenu()
        updateMenuBarMenu()
        let menuBarItem = NSMenuItem(title: "Menu Bar Display", action: nil, keyEquivalent: "")
        menuBarItem.submenu = menuBarMenu
        menu.addItem(menuBarItem)

        menu.addItem(NSMenuItem.separator())

        let addItem = NSMenuItem(title: "Add Cryptocurrency…", action: #selector(addCrypto), keyEquivalent: "")
        addItem.target = self
        menu.addItem(addItem)

        removeMenu = NSMenu()
        updateRemoveMenu()
        let removeItem = NSMenuItem(title: "Remove Cryptocurrency", action: nil, keyEquivalent: "")
        removeItem.submenu = removeMenu
        menu.addItem(removeItem)

        let resetItem = NSMenuItem(title: "Reset to Defaults", action: #selector(resetDefaults), keyEquivalent: "")
        resetItem.target = self
        menu.addItem(resetItem)

        menu.addItem(NSMenuItem.separator())

        let refreshItem = NSMenuItem(title: "Refresh Now", action: #selector(refreshPrices), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit CryptoFloat", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    func updateRemoveMenu() {
        removeMenu.removeAllItems()
        for symbol in config.cryptos {
            let item = NSMenuItem(title: symbol, action: #selector(removeCrypto(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = symbol
            removeMenu.addItem(item)
        }
    }

    func updateMenuBarMenu() {
        menuBarMenu.removeAllItems()

        let iconItem = NSMenuItem(title: "Icon Only (₿)", action: #selector(setMenuBarSymbol(_:)), keyEquivalent: "")
        iconItem.target = self
        iconItem.representedObject = nil
        iconItem.state = (config.menuBarSymbol == nil) ? .on : .off
        menuBarMenu.addItem(iconItem)

        if !config.cryptos.isEmpty {
            menuBarMenu.addItem(NSMenuItem.separator())
        }

        for symbol in config.cryptos {
            let item = NSMenuItem(title: symbol, action: #selector(setMenuBarSymbol(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = symbol
            item.state = (config.menuBarSymbol == symbol) ? .on : .off
            menuBarMenu.addItem(item)
        }
    }

    func updateFloatingWidgetMenu() {
        floatingWidgetMenu.removeAllItems()

        let choices: [(title: String, mode: FloatingWidgetMode)] = [
            ("Simple Bitcoin", .bitcoin),
            ("Marquee Prices", .marquee)
        ]

        for choice in choices {
            let item = NSMenuItem(title: choice.title, action: #selector(setFloatingWidgetMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = choice.mode.rawValue
            item.state = config.floatingWidgetMode == choice.mode ? .on : .off
            floatingWidgetMenu.addItem(item)
        }
    }

    func updateThemeMenu() {
        themeMenu.removeAllItems()

        for theme in ThemeCatalog.all {
            let item = NSMenuItem(title: theme.displayName, action: #selector(setTheme(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = theme.id.rawValue
            item.state = config.theme == theme.id ? .on : .off
            themeMenu.addItem(item)
        }
    }

    func updateDataProviderMenu() {
        dataProviderMenu.removeAllItems()

        for provider in DataProvider.allCases {
            let item = NSMenuItem(title: provider.displayName, action: #selector(setDataProvider(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = provider.rawValue
            item.state = config.dataProvider == provider ? .on : .off
            dataProviderMenu.addItem(item)
        }
    }

    func updateWindowShadow() {
        floatingWindow?.hasShadow = shouldUseWindowShadow
    }

    func calculateWindowSize() -> (width: CGFloat, height: CGFloat) {
        if config.isExpanded {
            if config.floatingWidgetMode == .marquee {
                let height = panelContentHeight + toggleButtonSize + 15
                return (expandedWidth, max(height, toggleButtonSize + 10))
            }
            return (expandedWidth, max(panelContentHeight + 10, toggleButtonSize + 10))
        } else {
            return (floatingWidgetWidth + 10, toggleButtonSize + 10)
        }
    }

    func setupWindow() {
        let (width, height) = calculateWindowSize()
        let frame = NSRect(x: config.windowX, y: config.windowY, width: Double(width), height: Double(height))

        floatingWindow = FloatingWindow(contentRect: frame, styleMask: [], backing: .buffered, defer: false)
        floatingWindow.alphaValue = 1
        floatingWindow.hasShadow = shouldUseWindowShadow

        containerView = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        floatingWindow.contentView = containerView

        setupFloatingWidget()

        setupContentPanel()

        floatingWindow.makeKeyAndOrderFront(nil)
    }

    func setupFloatingWidget() {
        toggleButton?.removeFromSuperview()
        marqueeWidget?.removeFromSuperview()
        toggleButton = nil
        marqueeWidget = nil

        let frame = floatingWidgetFrame()

        switch config.floatingWidgetMode {
        case .bitcoin:
            let button = ToggleButtonView(frame: frame)
            button.isExpanded = config.isExpanded
            button.backgroundOpacity = CGFloat(config.transparency)
            button.onClick = { [weak self] in
                self?.toggleExpanded()
            }
            containerView.addSubview(button)
            toggleButton = button

        case .marquee:
            let marquee = MarqueeWidgetView(frame: frame)
            marquee.backgroundOpacity = CGFloat(config.transparency)
            marquee.onClick = { [weak self] in
                self?.toggleExpanded()
            }
            marquee.setMarketData(symbols: config.cryptos, prices: latestPrices)
            containerView.addSubview(marquee)
            marqueeWidget = marquee
        }

        updateAccent()
    }

    func floatingWidgetFrame() -> NSRect {
        if config.floatingWidgetMode == .marquee, config.isExpanded {
            return NSRect(
                x: 5,
                y: max(containerView.bounds.height - toggleButtonSize - 5, 5),
                width: floatingWidgetWidth,
                height: toggleButtonSize
            )
        }

        return NSRect(x: 5, y: 5, width: floatingWidgetWidth, height: toggleButtonSize)
    }

    func layoutFloatingWidget() {
        let frame = floatingWidgetFrame()
        toggleButton?.frame = frame
        toggleButton?.isExpanded = config.isExpanded
        toggleButton?.backgroundOpacity = CGFloat(config.transparency)
        marqueeWidget?.frame = frame
        marqueeWidget?.backgroundOpacity = CGFloat(config.transparency)
        marqueeWidget?.setMarketData(symbols: config.cryptos, prices: latestPrices)
    }

    func setupContentPanel() {
        contentPanel?.removeFromSuperview()
        cryptoRows.removeAll()
        updatedLabel = nil

        guard config.isExpanded else { return }

        let contentHeight = panelContentHeight
        let panelW = currentPanelWidth
        let panelX: CGFloat
        if config.floatingWidgetMode == .marquee {
            panelX = max((containerView.bounds.width - panelW) / 2, 5)
        } else {
            panelX = floatingWidgetWidth + 10
        }

        contentPanel = GlassContentView(frame: NSRect(x: panelX, y: 5, width: panelW, height: contentHeight))
        contentPanel?.backgroundOpacity = CGFloat(config.transparency)
        containerView.addSubview(contentPanel!)

        let titleLabel = NSTextField(labelWithString: "PRICES · \(config.dataProvider.quoteLabel)")
        titleLabel.font = NSFont.systemFont(ofSize: 9, weight: .semibold)
        titleLabel.textColor = ThemeCatalog.current.accent.color(alpha: 0.8)
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.frame = NSRect(x: 14, y: contentHeight - 23, width: 80, height: 16)
        contentPanel?.addSubview(titleLabel)

        let updated = NSTextField(labelWithString: "")
        updated.font = NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .regular)
        updated.alignment = .right
        updated.textColor = ThemeCatalog.current.accent.color(alpha: 0.5)
        updated.isBezeled = false
        updated.drawsBackground = false
        updated.isEditable = false
        updated.frame = NSRect(x: panelW - 124, y: contentHeight - 23, width: 110, height: 16)
        contentPanel?.addSubview(updated)
        updatedLabel = updated

        for (index, symbol) in config.cryptos.enumerated() {
            let yPos = contentHeight - headerHeight - (CGFloat(index + 1) * rowHeight)

            let row = CryptoRowView(
                frame: NSRect(x: 0, y: yPos, width: panelW, height: rowHeight),
                symbol: symbol,
                showSparkline: config.showSparklines
            )
            row.onClick = { [weak self] _ in
                self?.showChartPopup(for: symbol)
            }
            contentPanel?.addSubview(row)
            cryptoRows[symbol] = row

            if let cached = sparklineCache[symbol]?.values {
                row.setSparkline(cached)
            }
        }

        updateStatusLabel()
    }

    private func chartAnchorScreenRect() -> NSRect {
        if let panel = contentPanel {
            let panelInWindow = panel.convert(panel.bounds, to: nil)
            return floatingWindow.convertToScreen(panelInWindow)
        }

        if let contentView = floatingWindow.contentView {
            let contentInWindow = contentView.convert(contentView.bounds, to: nil)
            return floatingWindow.convertToScreen(contentInWindow)
        }

        return floatingWindow.frame
    }

    func showChartPopup(for symbol: String) {
        hideChartPopup()
        activeChartSymbol = symbol

        let anchor = chartAnchorScreenRect()
        var origin = NSPoint(
            x: anchor.maxX + 10,
            y: anchor.maxY - chartPopupSize.height
        )

        if let visibleFrame = floatingWindow.screen?.visibleFrame ?? NSScreen.main?.visibleFrame {
            if origin.x + chartPopupSize.width > visibleFrame.maxX - 8 {
                origin.x = anchor.minX - chartPopupSize.width - 10
            }
            origin.x = min(max(origin.x, visibleFrame.minX + 8), visibleFrame.maxX - chartPopupSize.width - 8)
            origin.y = min(max(origin.y, visibleFrame.minY + 8), visibleFrame.maxY - chartPopupSize.height - 8)
        }

        let frame = NSRect(origin: origin, size: chartPopupSize)
        let popup = ChartPopupWindow(contentRect: frame, styleMask: [], backing: .buffered, defer: false)
        popup.alphaValue = 1
        popup.acceptsMouseMovedEvents = true

        let content = SevenDayChartContentView(
            frame: NSRect(origin: .zero, size: chartPopupSize),
            symbol: symbol,
            latest: latestPrices[symbol]
        )
        content.backgroundOpacity = CGFloat(config.transparency)
        popup.contentView = content
        content.needsDisplay = true
        chartWindow = popup
        chartContentView = content

        popup.displayIfNeeded()
        popup.orderFront(nil)
        installChartDismissalMonitors()

        if let cached = chartCache[symbol], Date().timeIntervalSince(cached.fetchedAt) < 600 {
            content.setPoints(cached.points)
            return
        }

        CryptoAPI.shared.fetchSevenDayChart(for: symbol, provider: config.dataProvider) { [weak self, weak content] points in
            guard let self = self, self.activeChartSymbol == symbol else { return }
            if !points.isEmpty {
                self.chartCache[symbol] = (points, Date())
            }
            content?.setSummary(self.latestPrices[symbol])
            content?.setPoints(points)
        }
    }

    func hideChartPopup() {
        removeChartDismissalMonitors()
        chartWindow?.orderOut(nil)
        chartWindow = nil
        chartContentView = nil
        activeChartSymbol = nil
    }

    private func installChartDismissalMonitors() {
        removeChartDismissalMonitors()

        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.chartWindow != nil else { return }

            var monitors: [Any] = []
            if let local = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown], handler: { [weak self] _ in
                self?.hideChartPopup()
                return nil
            }) {
                monitors.append(local)
            }

            if let global = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown], handler: { [weak self] _ in
                DispatchQueue.main.async {
                    self?.hideChartPopup()
                }
            }) {
                monitors.append(global)
            }

            self.chartDismissalMonitors = monitors
        }
    }

    private func removeChartDismissalMonitors() {
        for monitor in chartDismissalMonitors {
            NSEvent.removeMonitor(monitor)
        }
        chartDismissalMonitors.removeAll()
    }

    func toggleExpanded() {
        hideChartPopup()
        config.isExpanded.toggle()
        config.save()
        updateWindowShadow()

        toggleButton?.isExpanded = config.isExpanded
        expandCollapseItem.title = config.isExpanded ? "Collapse Prices" : "Expand Prices"

        let (width, height) = calculateWindowSize()
        var frame = floatingWindow.frame
        frame.origin.y += frame.size.height - height
        frame.size = NSSize(width: width, height: height)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            floatingWindow.animator().setFrame(frame, display: true)
        }

        containerView.frame = NSRect(x: 0, y: 0, width: width, height: height)
        layoutFloatingWidget()

        if config.isExpanded {
            setupContentPanel()
            refreshPrices()
        } else {
            contentPanel?.removeFromSuperview()
            contentPanel = nil
            updatedLabel = nil
        }
    }

    func rebuildWindow() {
        guard config.isExpanded else { return }
        hideChartPopup()
        updateWindowShadow()

        let (width, height) = calculateWindowSize()
        var frame = floatingWindow.frame
        frame.origin.y += frame.size.height - height
        frame.size = NSSize(width: width, height: height)
        floatingWindow.setFrame(frame, display: true)

        containerView.frame = NSRect(x: 0, y: 0, width: width, height: height)
        setupFloatingWidget()

        setupContentPanel()
        refreshPrices()
    }

    // MARK: - Timer
    func startUpdateTimer() {
        refreshPrices()
        updateTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(config.refreshRate), repeats: true) { [weak self] _ in
            self?.refreshPrices()
        }
    }

    func restartUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(config.refreshRate), repeats: true) { [weak self] _ in
            self?.refreshPrices()
        }
    }

    @objc func refreshPrices() {
        guard !config.cryptos.isEmpty else {
            latestPrices = [:]
            marqueeWidget?.setMarketData(symbols: config.cryptos, prices: latestPrices)
            updateMenuBarTitle()
            updateAccent()
            updateStatusLabel()
            return
        }

        CryptoAPI.shared.fetchAllPrices(for: config.cryptos, provider: config.dataProvider) { [weak self] prices in
            guard let self = self else { return }
            self.latestPrices = prices
            self.marqueeWidget?.setMarketData(symbols: self.config.cryptos, prices: prices)

            if self.config.isExpanded {
                for (symbol, data) in prices {
                    self.cryptoRows[symbol]?.update(price: data.price, change: data.change24h, hasError: data.hasError)
                }
            }
            if let activeSymbol = self.activeChartSymbol {
                self.chartContentView?.setSummary(prices[activeSymbol])
            }
            self.updateMenuBarTitle()
            self.updateAccent()
            self.updateStatusLabel()
            if self.config.isExpanded {
                self.refreshSparklines()
            }
        }
    }

    /// Fetches sparkline data for tracked coins, throttled so each symbol is
    /// only re-fetched roughly every 5 minutes regardless of the price refresh rate.
    func refreshSparklines() {
        guard config.isExpanded, config.showSparklines else { return }

        let now = Date()
        for symbol in config.cryptos {
            if let cached = sparklineCache[symbol] {
                cryptoRows[symbol]?.setSparkline(cached.values)
                if now.timeIntervalSince(cached.fetchedAt) < 290 { continue }
            }
            CryptoAPI.shared.fetchSparkline(for: symbol, provider: config.dataProvider) { [weak self] values in
                guard let self = self else { return }
                if !values.isEmpty {
                    self.sparklineCache[symbol] = (values, Date())
                    self.cryptoRows[symbol]?.setSparkline(values)
                }
            }
        }
    }

    func updateMenuBarTitle() {
        guard let button = statusItem.button else { return }
        if let sym = config.menuBarSymbol, let data = latestPrices[sym], !data.hasError, data.price > 0 {
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
            button.title = "\(sym) \(PriceFormatter.shared.compact(data.price))"
        } else {
            button.font = NSFont.systemFont(ofSize: 14)
            button.title = "₿"
        }
    }

    func updateAccent() {
        let primary = config.menuBarSymbol ?? config.cryptos.first
        if let p = primary, let data = latestPrices[p], !data.hasError {
            toggleButton?.accentChange = data.change24h
            marqueeWidget?.accentChange = data.change24h
        } else {
            toggleButton?.accentChange = 0
            marqueeWidget?.accentChange = 0
        }
    }

    func updateStatusLabel() {
        guard let label = updatedLabel else { return }
        let symbols = config.cryptos
        if symbols.isEmpty {
            label.stringValue = ""
            return
        }
        let erroredCount = symbols.filter { (latestPrices[$0]?.hasError ?? true) }.count
        if erroredCount == symbols.count {
            label.stringValue = "reconnecting…"
            label.textColor = ThemeCatalog.current.negative.color(alpha: 0.7)
        } else {
            label.stringValue = "updated \(timeFormatter.string(from: Date()))"
            label.textColor = ThemeCatalog.current.accent.color(alpha: 0.55)
        }
    }

    // MARK: - Actions
    @objc func toggleWindowVisibility() {
        if floatingWindow.isVisible {
            hideChartPopup()
            floatingWindow.orderOut(nil)
        } else {
            floatingWindow.makeKeyAndOrderFront(nil)
        }
    }

    @objc func toggleExpandedFromMenu() {
        toggleExpanded()
    }

    @objc func setFloatingWidgetMode(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let mode = FloatingWidgetMode(rawValue: rawValue),
              mode != config.floatingWidgetMode else {
            return
        }

        hideChartPopup()
        config.floatingWidgetMode = mode
        config.save()
        updateFloatingWidgetMenu()
        updateWindowShadow()

        let (width, height) = calculateWindowSize()
        var frame = floatingWindow.frame
        frame.origin.y += frame.size.height - height
        frame.size = NSSize(width: width, height: height)
        floatingWindow.setFrame(frame, display: true)

        containerView.frame = NSRect(x: 0, y: 0, width: width, height: height)
        setupFloatingWidget()
        setupContentPanel()

        refreshPrices()
    }

    @objc func setTheme(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let themeName = AppThemeName(rawValue: rawValue),
              themeName != config.theme else {
            return
        }

        config.theme = themeName
        ThemeCatalog.current = ThemeCatalog.theme(for: themeName)
        config.save()
        updateThemeMenu()

        if config.isExpanded {
            rebuildWindow()
        } else {
            setupFloatingWidget()
            refreshPrices()
        }

        chartContentView?.needsDisplay = true
        updateStatusLabel()
    }

    @objc func setDataProvider(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let provider = DataProvider(rawValue: rawValue),
              provider != config.dataProvider else {
            return
        }

        hideChartPopup()
        config.dataProvider = provider
        config.save()
        updateDataProviderMenu()

        latestPrices.removeAll()
        sparklineCache.removeAll()
        chartCache.removeAll()
        marqueeWidget?.setMarketData(symbols: config.cryptos, prices: latestPrices)

        if config.isExpanded {
            rebuildWindow()
        } else {
            refreshPrices()
        }
    }

    @objc func setTransparency(_ sender: NSMenuItem) {
        let level = Double(sender.tag) / 100.0
        config.transparency = level
        config.save()
        floatingWindow.alphaValue = 1
        toggleButton?.backgroundOpacity = CGFloat(level)
        marqueeWidget?.backgroundOpacity = CGFloat(level)
        contentPanel?.backgroundOpacity = CGFloat(level)
        chartContentView?.backgroundOpacity = CGFloat(level)

        for item in transparencyMenu.items {
            item.state = item.tag == sender.tag ? .on : .off
        }
    }

    @objc func setRefreshRate(_ sender: NSMenuItem) {
        config.refreshRate = sender.tag
        config.save()

        for item in refreshRateMenu.items {
            item.state = item.tag == sender.tag ? .on : .off
        }

        restartUpdateTimer()
    }

    @objc func toggleSparklines(_ sender: NSMenuItem) {
        config.showSparklines.toggle()
        config.save()
        sparklineToggleItem.state = config.showSparklines ? .on : .off
        rebuildWindow()
        if config.showSparklines {
            refreshSparklines()
        }
    }

    @objc func setMenuBarSymbol(_ sender: NSMenuItem) {
        config.menuBarSymbol = sender.representedObject as? String
        config.save()
        updateMenuBarMenu()
        updateMenuBarTitle()
        updateAccent()
    }

    @objc func addCrypto() {
        let alert = NSAlert()
        alert.messageText = "Add Cryptocurrency"
        alert.informativeText = "Enter the trading symbol (e.g., 'BTC', 'ETH', 'SOL', 'DOGE').\n\nKuCoin and Binance use USDT pairs. CoinGecko uses USD aggregate data for supported mapped symbols."
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.placeholderString = "e.g., BTC"
        alert.accessoryView = textField

        if alert.runModal() == .alertFirstButtonReturn {
            let symbol = textField.stringValue.trimmingCharacters(in: .whitespaces).uppercased()
            if !symbol.isEmpty && !config.cryptos.contains(symbol) {
                config.cryptos.append(symbol)
                config.save()
                updateRemoveMenu()
                updateMenuBarMenu()
                rebuildWindow()
                if !config.isExpanded {
                    marqueeWidget?.setMarketData(symbols: config.cryptos, prices: latestPrices)
                    refreshPrices()
                }
            }
        }
    }

    @objc func removeCrypto(_ sender: NSMenuItem) {
        guard let symbol = sender.representedObject as? String else { return }
        if activeChartSymbol == symbol {
            hideChartPopup()
        }
        config.cryptos.removeAll { $0 == symbol }
        sparklineCache[symbol] = nil
        chartCache[symbol] = nil
        if config.menuBarSymbol == symbol {
            config.menuBarSymbol = nil
        }
        config.save()
        updateRemoveMenu()
        updateMenuBarMenu()
        updateMenuBarTitle()
        rebuildWindow()
        if !config.isExpanded {
            marqueeWidget?.setMarketData(symbols: config.cryptos, prices: latestPrices)
            refreshPrices()
        }
    }

    @objc func resetDefaults() {
        hideChartPopup()
        config.cryptos = AppConfig.default.cryptos
        config.refreshRate = AppConfig.default.refreshRate
        config.floatingWidgetMode = AppConfig.default.floatingWidgetMode
        config.theme = AppConfig.default.theme
        config.dataProvider = AppConfig.default.dataProvider
        ThemeCatalog.current = ThemeCatalog.theme(for: config.theme)
        sanitizeMenuBarSymbol()
        config.save()
        updateWindowShadow()
        updateRemoveMenu()
        updateMenuBarMenu()
        updateFloatingWidgetMenu()
        updateThemeMenu()
        updateDataProviderMenu()
        updateMenuBarTitle()
        rebuildWindow()
        if !config.isExpanded {
            let (width, height) = calculateWindowSize()
            var frame = floatingWindow.frame
            frame.origin.y += frame.size.height - height
            frame.size = NSSize(width: width, height: height)
            floatingWindow.setFrame(frame, display: true)
            containerView.frame = NSRect(x: 0, y: 0, width: width, height: height)
            setupFloatingWidget()
            refreshPrices()
        }
        restartUpdateTimer()

        for item in refreshRateMenu.items {
            item.state = item.tag == config.refreshRate ? .on : .off
        }
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

// MARK: - Main
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
