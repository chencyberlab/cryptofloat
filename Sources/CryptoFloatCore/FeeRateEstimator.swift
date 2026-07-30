import Foundation

enum FeeRateEstimator {
    static func conservativeRate(_ values: [Double?]) -> Double? {
        let valid = values
            .compactMap { $0 }
            .filter { $0.isFinite && $0 > 0 && $0 < 1_000 }
            .sorted()
        guard !valid.isEmpty else { return nil }
        guard valid.count > 2 else { return valid.last }

        // Use the upper quartile without allowing the maximum of a four-source
        // sample to dominate the result.
        let index = Int(floor(Double(valid.count - 1) * 0.75))
        return valid[index]
    }
}
