import Foundation

struct FailureBackoff {
    private(set) var consecutiveFailures = 0
    private(set) var retryAfter = Date.distantPast

    func allowsAttempt(at date: Date) -> Bool {
        return date >= retryAfter
    }

    mutating func recordFailure(
        at date: Date = Date(),
        baseDelay: TimeInterval = 30,
        maximumDelay: TimeInterval = 600
    ) {
        consecutiveFailures = min(consecutiveFailures + 1, 8)
        let exponent = Double(max(consecutiveFailures - 1, 0))
        let delay = min(baseDelay * pow(2, exponent), maximumDelay)
        retryAfter = date.addingTimeInterval(delay)
    }

    mutating func reset() {
        consecutiveFailures = 0
        retryAfter = .distantPast
    }
}
