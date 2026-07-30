import Foundation
import XCTest
@testable import CryptoFloatCore

final class AppConfigTests: XCTestCase {
    func testNormalizedSymbolTrimsAndUppercasesASCII() {
        XCTAssertEqual(AppConfig.normalizedSymbol(" eth \n"), "ETH")
        XCTAssertEqual(AppConfig.normalizedSymbol("btc2"), "BTC2")
    }

    func testNormalizedSymbolRejectsInvalidValues() {
        XCTAssertNil(AppConfig.normalizedSymbol(""))
        XCTAssertNil(AppConfig.normalizedSymbol("   \n"))
        XCTAssertNil(AppConfig.normalizedSymbol("BTC-USD"))
        XCTAssertNil(AppConfig.normalizedSymbol("BTC_USD"))
        XCTAssertNil(AppConfig.normalizedSymbol("ÉTH"))
        XCTAssertNil(AppConfig.normalizedSymbol("🚀"))
        XCTAssertNil(AppConfig.normalizedSymbol(String(repeating: "A", count: 16)))
    }

    func testNormalizationDeduplicatesPreservesOrderAndCapsWatchlist() {
        var config = AppConfig.default
        config.cryptos = [" eth ", "BTC", "ETH"]
            + (0..<25).map { "C\($0)" }

        let normalized = config.normalized()

        XCTAssertEqual(normalized.cryptos.count, AppConfig.maximumTrackedSymbols)
        XCTAssertEqual(Array(normalized.cryptos.prefix(4)), ["ETH", "BTC", "C0", "C1"])
        XCTAssertEqual(Set(normalized.cryptos).count, normalized.cryptos.count)
        XCTAssertEqual(normalized.cryptos.last, "C17")
    }

    func testNormalizationClampsDisplayAndRefreshValues() {
        var low = AppConfig.default
        low.transparency = 0.1
        low.refreshRate = 17
        low.windowX = .nan
        low.windowY = .infinity

        let normalizedLow = low.normalized()
        XCTAssertEqual(normalizedLow.transparency, 0.5)
        XCTAssertEqual(normalizedLow.refreshRate, AppConfig.default.refreshRate)
        XCTAssertEqual(normalizedLow.windowX, AppConfig.default.windowX)
        XCTAssertEqual(normalizedLow.windowY, AppConfig.default.windowY)

        var high = AppConfig.default
        high.transparency = 1.5
        XCTAssertEqual(high.normalized().transparency, 1)

        var nonFinite = AppConfig.default
        nonFinite.transparency = .nan
        XCTAssertEqual(nonFinite.normalized().transparency, AppConfig.default.transparency)
    }

    func testNormalizationKeepsOnlyTrackedMenuBarSymbol() {
        var config = AppConfig.default
        config.cryptos = ["btc", " eth "]
        config.menuBarSymbol = " BTC "
        XCTAssertEqual(config.normalized().menuBarSymbol, "BTC")

        config.menuBarSymbol = "SOL"
        XCTAssertNil(config.normalized().menuBarSymbol)

        config.menuBarSymbol = "BTC-USD"
        XCTAssertNil(config.normalized().menuBarSymbol)
    }

    func testTolerantDecodingRetainsValidFieldsAndDefaultsMalformedFields() throws {
        let json = """
        {
          "cryptos": [" eth ", "BTC", "ETH"],
          "transparency": "opaque",
          "windowX": 250.5,
          "windowY": false,
          "isExpanded": false,
          "refreshRate": 15,
          "showSparklines": "yes",
          "menuBarSymbol": "eth",
          "floatingWidgetMode": "futureMode",
          "theme": "futureTheme",
          "dataProvider": "binance",
          "showNetworkFees": true
        }
        """

        let decoded = try JSONDecoder().decode(
            AppConfig.self,
            from: try XCTUnwrap(json.data(using: .utf8))
        ).normalized()

        XCTAssertEqual(decoded.cryptos, ["ETH", "BTC"])
        XCTAssertEqual(decoded.transparency, AppConfig.default.transparency)
        XCTAssertEqual(decoded.windowX, 250.5)
        XCTAssertEqual(decoded.windowY, AppConfig.default.windowY)
        XCTAssertFalse(decoded.isExpanded)
        XCTAssertEqual(decoded.refreshRate, 15)
        XCTAssertEqual(decoded.showSparklines, AppConfig.default.showSparklines)
        XCTAssertEqual(decoded.menuBarSymbol, "ETH")
        XCTAssertEqual(decoded.floatingWidgetMode, AppConfig.default.floatingWidgetMode)
        XCTAssertEqual(decoded.theme, AppConfig.default.theme)
        XCTAssertEqual(decoded.dataProvider, .binance)
        XCTAssertTrue(decoded.showNetworkFees)
    }

    func testEmptyObjectDecodesToDefaults() throws {
        let decoded = try JSONDecoder().decode(AppConfig.self, from: Data("{}".utf8))

        XCTAssertEqual(decoded.cryptos, AppConfig.default.cryptos)
        XCTAssertEqual(decoded.transparency, AppConfig.default.transparency)
        XCTAssertEqual(decoded.refreshRate, AppConfig.default.refreshRate)
        XCTAssertEqual(decoded.floatingWidgetMode, AppConfig.default.floatingWidgetMode)
        XCTAssertEqual(decoded.theme, AppConfig.default.theme)
        XCTAssertEqual(decoded.dataProvider, AppConfig.default.dataProvider)
    }

    func testEncodingRoundTripPreservesEveryConfigurationField() throws {
        var original = AppConfig.default
        original.cryptos = ["BTC", "ETH", "1INCH"]
        original.transparency = 0.6
        original.windowX = -245.5
        original.windowY = 812.25
        original.isExpanded = false
        original.refreshRate = 120
        original.showSparklines = false
        original.menuBarSymbol = "ETH"
        original.floatingWidgetMode = .marquee
        original.theme = .cyberpunkNeon
        original.dataProvider = .binance
        original.showNetworkFees = true

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AppConfig.self, from: encoded)

        XCTAssertEqual(decoded.cryptos, original.cryptos)
        XCTAssertEqual(decoded.transparency, original.transparency)
        XCTAssertEqual(decoded.windowX, original.windowX)
        XCTAssertEqual(decoded.windowY, original.windowY)
        XCTAssertEqual(decoded.isExpanded, original.isExpanded)
        XCTAssertEqual(decoded.refreshRate, original.refreshRate)
        XCTAssertEqual(decoded.showSparklines, original.showSparklines)
        XCTAssertEqual(decoded.menuBarSymbol, original.menuBarSymbol)
        XCTAssertEqual(decoded.floatingWidgetMode, original.floatingWidgetMode)
        XCTAssertEqual(decoded.theme, original.theme)
        XCTAssertEqual(decoded.dataProvider, original.dataProvider)
        XCTAssertEqual(decoded.showNetworkFees, original.showNetworkFees)
    }
}
