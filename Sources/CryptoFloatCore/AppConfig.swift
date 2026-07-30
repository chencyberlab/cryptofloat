import Foundation

// MARK: - Configuration
enum AppThemeName: String, Codable, CaseIterable, Hashable {
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
    var showNetworkFees: Bool

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
        dataProvider: .kuCoin,
        showNetworkFees: false
    )

    static let configPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".cryptofloat_config.json")

    static let supportedRefreshRates: Set<Int> = [5, 10, 15, 30, 60, 120, 300]
    static let maximumTrackedSymbols = 20

    static func normalizedSymbol(_ rawValue: String) -> String? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty,
              trimmed.count <= 15,
              trimmed.unicodeScalars.allSatisfy({
                  (65...90).contains($0.value)
                      || (97...122).contains($0.value)
                      || (48...57).contains($0.value)
              }) else {
            return nil
        }
        return trimmed.uppercased()
    }

    func normalized() -> AppConfig {
        var value = self
        var seen: Set<String> = []
        value.cryptos = cryptos.compactMap { rawValue in
            guard seen.count < AppConfig.maximumTrackedSymbols,
                  let symbol = AppConfig.normalizedSymbol(rawValue),
                  seen.insert(symbol).inserted else {
                return nil
            }
            return symbol
        }

        value.transparency = transparency.isFinite
            ? min(max(transparency, 0.5), 1.0)
            : AppConfig.default.transparency
        value.windowX = windowX.isFinite ? windowX : AppConfig.default.windowX
        value.windowY = windowY.isFinite ? windowY : AppConfig.default.windowY
        value.refreshRate = AppConfig.supportedRefreshRates.contains(refreshRate)
            ? refreshRate
            : AppConfig.default.refreshRate

        if let menuSymbol = menuBarSymbol.flatMap(AppConfig.normalizedSymbol),
           value.cryptos.contains(menuSymbol) {
            value.menuBarSymbol = menuSymbol
        } else {
            value.menuBarSymbol = nil
        }

        return value
    }

    static func load() -> AppConfig {
        guard let data = try? Data(contentsOf: configPath),
              let config = try? JSONDecoder().decode(AppConfig.self, from: data) else {
            return .default
        }
        return config.normalized()
    }

    func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try encoder.encode(normalized())
            try data.write(to: AppConfig.configPath, options: .atomic)
        } catch {
            NSLog("CryptoFloat could not save its configuration: %@", error.localizedDescription)
        }
    }
}

// Tolerant decoding: a missing or malformed key falls back to its default
// instead of throwing away the entire saved configuration. This keeps older
// config files (and future schema changes) working seamlessly.
extension AppConfig {
    enum CodingKeys: String, CodingKey {
        case cryptos, transparency, windowX, windowY, isExpanded, refreshRate, showSparklines, menuBarSymbol, floatingWidgetMode, theme, dataProvider, showNetworkFees
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
        showNetworkFees = (try? c.decode(Bool.self, forKey: .showNetworkFees)) ?? d.showNetworkFees
    }
}
