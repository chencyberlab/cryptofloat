import Foundation

// MARK: - Price Data
struct PriceData: Equatable {
    let price: Double
    let change24h: Double?
    let hasError: Bool
}

struct ChartPoint: Equatable {
    let time: TimeInterval
    let price: Double
}

struct NetworkFeeTier: Equatable {
    let label: String
    let rate: Double
    let unit: String
    let usdValue: Double?
    let eta: String
}

struct NetworkFeeData: Equatable {
    let eth: [NetworkFeeTier]
    let btc: [NetworkFeeTier]
    let updatedAt: Date
    let hasError: Bool
}
