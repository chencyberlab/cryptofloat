import CoreFoundation
import Foundation

enum NumericValue {
    static func finiteDouble(from value: Any?) -> Double? {
        let number: Double?
        if let value = value as? NSNumber {
            guard CFGetTypeID(value) != CFBooleanGetTypeID() else { return nil }
            number = value.doubleValue
        } else if let value = value as? String {
            number = Double(value)
        } else {
            number = nil
        }

        guard let number = number, number.isFinite else { return nil }
        return number
    }

    static func positiveDouble(from value: Any?) -> Double? {
        guard let number = finiteDouble(from: value), number > 0 else { return nil }
        return number
    }

    static func hexadecimalDouble(from value: String) -> Double? {
        let digits = value.hasPrefix("0x") ? String(value.dropFirst(2)) : value
        guard !digits.isEmpty, let integer = UInt64(digits, radix: 16) else { return nil }
        return Double(integer)
    }
}
