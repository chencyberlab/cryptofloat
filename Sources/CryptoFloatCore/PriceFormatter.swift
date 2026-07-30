import Foundation

// MARK: - Price Formatter
class PriceFormatter {
    static let shared = PriceFormatter()
    private let formattingLocale: Locale

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

    init(locale: Locale = .current) {
        formattingLocale = locale
        currencyFormatter.locale = locale
        smallPriceFormatter.locale = locale
        groupedFormatter.locale = locale
    }

    func format(_ price: Double) -> String {
        guard price.isFinite, price >= 0 else { return "—" }
        let normalizedPrice = price == 0 ? 0 : price
        if normalizedPrice >= 1 {
            // Normal prices: $90,719.00, $3,097.70, $136.42
            return currencyFormatter.string(from: NSNumber(value: normalizedPrice)) ?? "$0.00"
        } else if normalizedPrice >= 0.0001 {
            // Small prices: $0.0012
            return smallPriceFormatter.string(from: NSNumber(value: normalizedPrice)) ?? "$0.0000"
        } else {
            // Very small prices: more decimals
            return String(
                format: "$%.8f",
                locale: formattingLocale,
                arguments: [normalizedPrice]
            )
        }
    }

    /// Compact form used in the menu bar where horizontal space is scarce.
    func compact(_ price: Double) -> String {
        guard price.isFinite, price >= 0 else { return "—" }
        let normalizedPrice = price == 0 ? 0 : price
        let roundedPrice = normalizedPrice.rounded()
        if roundedPrice >= 1000 {
            let rounded = NSNumber(value: roundedPrice)
            return "$" + (groupedFormatter.string(from: rounded) ?? "0")
        } else if normalizedPrice >= 1 {
            return String(
                format: "$%.2f",
                locale: formattingLocale,
                arguments: [normalizedPrice]
            )
        }
        return format(normalizedPrice)
    }
}
