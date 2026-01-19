//
//  RetryPolicy.swift
//  EZNetworking
//
//  Created by Gerard Gomez on 9/3/24.
//

import Foundation

/// A policy that controls automatic retries for network requests.
public struct RetryPolicy: Sendable {
    /// A jitter strategy for retry delays.
    public enum Jitter: Sendable {
        /// No jitter is applied.
        case none
        /// Apply jitter as a fractional multiplier (0.0 to 1.0).
        case fractional(Double)
    }

    /// The maximum number of attempts, including the initial request.
    public let maximumAttempts: Int
    /// The initial delay before the first retry.
    public let initialDelay: Duration
    /// The maximum delay cap for retries.
    public let maximumDelay: Duration
    /// The multiplier used for exponential backoff.
    public let multiplier: Double
    /// The jitter strategy to apply to delays.
    public let jitter: Jitter
    /// A predicate that determines whether a given error should be retried.
    public let shouldRetry: @Sendable (Error) -> Bool

    /// Creates a retry policy with exponential backoff and optional jitter.
    ///
    /// - Parameters:
    ///   - maximumAttempts: The total number of attempts, including the initial request.
    ///   - initialDelay: The initial delay before the first retry.
    ///   - maximumDelay: The maximum delay cap for retries.
    ///   - multiplier: The exponential backoff multiplier.
    ///   - jitter: The jitter strategy to apply to delay calculations.
    ///   - shouldRetry: A predicate that determines which errors should be retried.
    public init(
        maximumAttempts: Int = 3,
        initialDelay: Duration = .seconds(0.5),
        maximumDelay: Duration = .seconds(8),
        multiplier: Double = 2,
        jitter: Jitter = .fractional(0.2),
        shouldRetry: @escaping @Sendable (Error) -> Bool = RetryPolicy.defaultRetryPredicate
    ) {
        let initialSeconds = max(0, Self.seconds(from: initialDelay))
        let maximumSeconds = max(initialSeconds, Self.seconds(from: maximumDelay))

        self.maximumAttempts = max(1, maximumAttempts)
        self.initialDelay = .seconds(initialSeconds)
        self.maximumDelay = .seconds(maximumSeconds)
        self.multiplier = max(1, multiplier)
        self.jitter = jitter
        self.shouldRetry = shouldRetry
    }

    /// Provides a default retry predicate that retries network errors and 5xx status codes.
    public static func defaultRetryPredicate(_ error: Error) -> Bool {
        guard let apiError = error as? APIError else {
            return false
        }

        switch apiError {
        case .networkError:
            return true
        case .httpStatusCodeFailed(let statusCode, _):
            return (500...599).contains(statusCode)
        case .unknownError:
            return true
        case .invalidURL, .decodingError:
            return false
        }
    }

    /// Calculates the delay for the given retry attempt.
    ///
    /// - Parameter attempt: The retry attempt number (starting at 1 for the first retry).
    /// - Returns: The calculated delay.
    public func delay(afterAttempt attempt: Int) -> Duration {
        let attemptIndex = max(1, attempt)
        let baseSeconds = Self.seconds(from: initialDelay) * pow(multiplier, Double(attemptIndex - 1))
        let cappedSeconds = min(baseSeconds, Self.seconds(from: maximumDelay))
        let jitteredSeconds = applyJitter(to: cappedSeconds)
        return .seconds(jitteredSeconds)
    }

    private func applyJitter(to seconds: Double) -> Double {
        guard seconds > 0 else {
            return 0
        }

        switch jitter {
        case .none:
            return seconds
        case .fractional(let fraction):
            let normalized = min(max(fraction, 0), 1)
            let range = (1 - normalized)...(1 + normalized)
            return seconds * Double.random(in: range)
        }
    }

    private static func seconds(from duration: Duration) -> Double {
        let components = duration.components
        return Double(components.seconds) + (Double(components.attoseconds) / 1_000_000_000_000_000_000)
    }
}
