import Foundation
import XCTest
@testable import CryptoFloatCore

final class FailureBackoffTests: XCTestCase {
    func testInitialStateAllowsImmediateAttempt() {
        let backoff = FailureBackoff()
        XCTAssertEqual(backoff.consecutiveFailures, 0)
        XCTAssertTrue(backoff.allowsAttempt(at: Date(timeIntervalSince1970: 0)))
    }

    func testDelayDoublesAndCapsAtMaximum() {
        var backoff = FailureBackoff()
        var failureDate = Date(timeIntervalSince1970: 1_000)
        let expectedDelays: [TimeInterval] = [30, 60, 120, 240, 480, 600, 600, 600]

        for (index, expectedDelay) in expectedDelays.enumerated() {
            backoff.recordFailure(at: failureDate)
            XCTAssertEqual(
                backoff.retryAfter,
                failureDate.addingTimeInterval(expectedDelay),
                "Unexpected delay after failure \(index + 1)"
            )
            XCTAssertEqual(backoff.consecutiveFailures, index + 1)
            failureDate = backoff.retryAfter
        }
    }

    func testFailureCountStaysCappedAtEight() {
        var backoff = FailureBackoff()
        let date = Date(timeIntervalSince1970: 1_000)

        for _ in 0..<12 {
            backoff.recordFailure(at: date)
        }

        XCTAssertEqual(backoff.consecutiveFailures, 8)
        XCTAssertEqual(backoff.retryAfter, date.addingTimeInterval(600))
    }

    func testAttemptIsAllowedAtExactRetryBoundary() {
        var backoff = FailureBackoff()
        let date = Date(timeIntervalSince1970: 1_000)
        backoff.recordFailure(at: date)

        XCTAssertFalse(backoff.allowsAttempt(at: backoff.retryAfter.addingTimeInterval(-0.001)))
        XCTAssertTrue(backoff.allowsAttempt(at: backoff.retryAfter))
    }

    func testResetRestoresInitialState() {
        var backoff = FailureBackoff()
        let date = Date(timeIntervalSince1970: 1_000)
        backoff.recordFailure(at: date)
        backoff.reset()

        XCTAssertEqual(backoff.consecutiveFailures, 0)
        XCTAssertEqual(backoff.retryAfter, .distantPast)
        XCTAssertTrue(backoff.allowsAttempt(at: date))
    }
}
