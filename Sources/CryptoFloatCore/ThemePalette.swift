import Foundation

struct RGBColor: Equatable {
    let red: Double
    let green: Double
    let blue: Double

    init(_ red: Double, _ green: Double, _ blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    func mixed(with other: RGBColor, fraction: Double) -> RGBColor {
        let amount = min(max(fraction, 0), 1)
        return RGBColor(
            red + ((other.red - red) * amount),
            green + ((other.green - green) * amount),
            blue + ((other.blue - blue) * amount)
        )
    }

    func contrastRatio(
        against background: RGBColor,
        alpha: Double = 1
    ) -> Double {
        let foreground = background.mixed(
            with: self,
            fraction: min(max(alpha, 0), 1)
        )
        let lighter = max(foreground.relativeLuminance, background.relativeLuminance)
        let darker = min(foreground.relativeLuminance, background.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    private var relativeLuminance: Double {
        func linearized(_ component: Double) -> Double {
            let normalized = min(max(component / 255, 0), 1)
            if normalized <= 0.04045 {
                return normalized / 12.92
            }
            return pow((normalized + 0.055) / 1.055, 2.4)
        }

        return (0.2126 * linearized(red))
            + (0.7152 * linearized(green))
            + (0.0722 * linearized(blue))
    }
}

struct AppTheme: Equatable {
    static let secondaryTextAlpha = 0.88
    static let subduedTextAlpha = 0.82
    static let accentTextBlend = 0.25
    static let negativeTextBlend = 0.25

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

    var accentText: RGBColor {
        return accent.mixed(
            with: foreground,
            fraction: AppTheme.accentTextBlend
        )
    }

    var negativeText: RGBColor {
        return negative.mixed(
            with: foreground,
            fraction: AppTheme.negativeTextBlend
        )
    }
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
                negative: RGBColor(239, 112, 122),
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
                negative: RGBColor(232, 117, 127),
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
                accent: RGBColor(254, 128, 25),
                accentSecondary: RGBColor(69, 133, 136),
                positive: RGBColor(184, 187, 38),
                negative: RGBColor(251, 73, 52),
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
