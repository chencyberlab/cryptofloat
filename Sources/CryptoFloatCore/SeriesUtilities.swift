import Foundation

enum SeriesUtilities {
    static func evenlySampled<T>(_ values: [T], maximumCount: Int) -> [T] {
        guard maximumCount > 0 else { return [] }
        guard values.count > maximumCount else { return values }
        guard maximumCount > 1 else { return values.last.map { [$0] } ?? [] }

        let lastIndex = values.count - 1
        return (0..<maximumCount).map { index in
            let ratio = Double(index) / Double(maximumCount - 1)
            return values[Int(round(ratio * Double(lastIndex)))]
        }
    }

    static func normalizedChartPoints(
        _ points: [ChartPoint],
        maximumCount: Int = 5_000,
        latestAllowedTime: TimeInterval = Date().timeIntervalSince1970 + 24 * 60 * 60
    ) -> [ChartPoint] {
        var pointByTime: [TimeInterval: ChartPoint] = [:]
        for point in points where point.time.isFinite
            && point.time > 0
            && point.time <= latestAllowedTime
            && point.price.isFinite
            && point.price > 0 {
            pointByTime[point.time] = point
        }

        let sorted = pointByTime.values.sorted { $0.time < $1.time }
        return evenlySampled(sorted, maximumCount: maximumCount)
    }
}
