import XCTest
@testable import CryptoFloatCore

final class ThemePaletteTests: XCTestCase {
    func testCatalogContainsEveryThemeExactlyOnce() {
        XCTAssertEqual(ThemeCatalog.all.count, AppThemeName.allCases.count)
        XCTAssertEqual(
            Set(ThemeCatalog.all.map(\.id)),
            Set(AppThemeName.allCases)
        )
        XCTAssertTrue(
            ThemeCatalog.all.allSatisfy { !$0.displayName.isEmpty }
        )
    }

    func testSemanticTextColorsMeetNormalTextContrastOnEveryThemeSurface() {
        for theme in ThemeCatalog.all {
            for background in [theme.background, theme.backgroundDark] {
                XCTAssertGreaterThanOrEqual(
                    theme.foreground.contrastRatio(
                        against: background,
                        alpha: AppTheme.secondaryTextAlpha
                    ),
                    4.5,
                    "\(theme.displayName) secondary text"
                )
                XCTAssertGreaterThanOrEqual(
                    theme.foreground.contrastRatio(
                        against: background,
                        alpha: AppTheme.subduedTextAlpha
                    ),
                    4.5,
                    "\(theme.displayName) subdued text"
                )
                XCTAssertGreaterThanOrEqual(
                    theme.accentText.contrastRatio(against: background),
                    4.5,
                    "\(theme.displayName) accent text"
                )
                XCTAssertGreaterThanOrEqual(
                    theme.negativeText.contrastRatio(against: background),
                    4.5,
                    "\(theme.displayName) negative text"
                )
                XCTAssertGreaterThanOrEqual(
                    theme.positive.contrastRatio(against: background),
                    4.5,
                    "\(theme.displayName) positive text"
                )
            }
        }
    }

    func testRGBMixAndAlphaCompositionAreClamped() {
        let black = RGBColor(0, 0, 0)
        let white = RGBColor(255, 255, 255)

        XCTAssertEqual(black.mixed(with: white, fraction: -1), black)
        XCTAssertEqual(black.mixed(with: white, fraction: 2), white)
        XCTAssertEqual(
            white.contrastRatio(against: black, alpha: -1),
            1,
            accuracy: 0.000_001
        )
        XCTAssertEqual(
            white.contrastRatio(against: black, alpha: 2),
            21,
            accuracy: 0.000_001
        )
    }
}
