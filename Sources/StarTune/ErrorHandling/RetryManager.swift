//
//  RetryManager.swift
//  StarTune
//
//  Retry logic with exponential backoff for async operations
//

import Foundation

/// Configuration for retry behavior
struct RetryConfig {
    /// Maximum number of retry attempts
    let maxAttempts: Int

    /// Base delay for exponential backoff (in seconds)
    let baseDelay: TimeInterval

    /// Maximum delay between retries (prevents excessive waiting)
    let maxDelay: TimeInterval

    /// Multiplier for exponential backoff
    let multiplier: Double

    /// Jitter factor (0.0 - 1.0) to add randomness to delays
    let jitter: Double

    /// Predicate to determine if an error should trigger a retry
    let shouldRetry: (Error) -> Bool

    /// Default configuration for network operations
    static let network = RetryConfig(
        maxAttempts: 3,
        baseDelay: 1.0,
        maxDelay: 30.0,
        multiplier: 2.0,
        jitter: 0.1,
        shouldRetry: { error in
            if let appError = error as? AppError {
                return appError.isRetryable
            }
            if let retryableError = error as? RetryableError {
                return retryableError.isRetryable
            }
            return false
        }
    )

    /// Configuration for critical operations (more attempts)
    static let critical = RetryConfig(
        maxAttempts: 5,
        baseDelay: 0.5,
        maxDelay: 60.0,
        multiplier: 2.0,
        jitter: 0.15,
        shouldRetry: { error in
            if let appError = error as? AppError {
                return appError.isRetryable
            }
            if let retryableError = error as? RetryableError {
                return retryableError.isRetryable
            }
            return false
        }
    )

    /// Configuration for quick retries (fewer attempts, shorter delays)
    static let quick = RetryConfig(
        maxAttempts: 2,
        baseDelay: 0.5,
        maxDelay: 5.0,
        multiplier: 2.0,
        jitter: 0.05,
        shouldRetry: { error in
            if let appError = error as? AppError {
                return appError.isRetryable
            }
            if let retryableError = error as? RetryableError {
                return retryableError.isRetryable
            }
            return false
        }
    )
}

/// Result of a retry operation
struct RetryResult<T> {
    /// The successful result
    let value: T

    /// Number of attempts made
    let attemptCount: Int

    /// Total time spent retrying
    let totalDuration: TimeInterval

    /// Errors encountered during retry attempts
    let errors: [Error]
}

/// Manager for retry operations with exponential backoff
actor RetryManager {
    /// Shared instance
    static let shared = RetryManager()

    /// Statistics for analytics
    private var retryStats: [String: RetryStats] = [:]

    private init() {}

    /// Execute an async operation with retry logic
    /// - Parameters:
    ///   - config: Retry configuration
    ///   - operation: The async operation to execute
    ///   - operationName: Name for analytics tracking
    /// - Returns: The result of the operation
    /// - Throws: The last error if all retries fail
    func retry<T>(
        config: RetryConfig = .network,
        operationName: String? = nil,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        let startTime = Date()
        var lastError: Error?
        var errors: [Error] = []
        var attempt = 0

        while attempt < config.maxAttempts {
            attempt += 1

            do {
                let result = try await operation()

                // Record success
                let duration = Date().timeIntervalSince(startTime)
                if let name = operationName {
                    await recordSuccess(
                        operationName: name,
                        attemptCount: attempt,
                        duration: duration
                    )
                }

                return result

            } catch {
                lastError = error
                errors.append(error)

                // Check if we should retry
                guard config.shouldRetry(error) else {
                    // Non-retryable error, fail immediately
                    if let name = operationName {
                        await recordFailure(
                            operationName: name,
                            error: error,
                            attemptCount: attempt,
                            wasRetryable: false
                        )
                    }
                    throw error
                }

                // Check if we've exhausted attempts
                if attempt >= config.maxAttempts {
                    if let name = operationName {
                        await recordFailure(
                            operationName: name,
                            error: error,
                            attemptCount: attempt,
                            wasRetryable: true
                        )
                    }
                    throw error
                }

                // Calculate delay with exponential backoff and jitter
                let delay = calculateDelay(
                    attempt: attempt,
                    config: config
                )

                #if DEBUG
                print("⚠️ Retry attempt \(attempt)/\(config.maxAttempts) after \(String(format: "%.1f", delay))s: \(error.localizedDescription)")
                #endif

                // Wait before retrying
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        // This should never be reached, but just in case
        throw lastError ?? AppError.operationError(.failed("All retry attempts failed"))
    }

    /// Calculate delay with exponential backoff and jitter
    private func calculateDelay(attempt: Int, config: RetryConfig) -> TimeInterval {
        // Exponential backoff: baseDelay * multiplier^(attempt-1)
        let exponentialDelay = config.baseDelay * pow(config.multiplier, Double(attempt - 1))

        // Cap at maxDelay
        let cappedDelay = min(exponentialDelay, config.maxDelay)

        // Add jitter to prevent thundering herd
        let jitterAmount = cappedDelay * config.jitter
        let jitter = TimeInterval.random(in: -jitterAmount...jitterAmount)

        return max(0, cappedDelay + jitter)
    }

    /// Record successful operation
    private func recordSuccess(
        operationName: String,
        attemptCount: Int,
        duration: TimeInterval
    ) {
        var stats = retryStats[operationName] ?? RetryStats(operationName: operationName)
        stats.recordSuccess(attemptCount: attemptCount, duration: duration)
        retryStats[operationName] = stats
    }

    /// Record failed operation
    private func recordFailure(
        operationName: String,
        error: Error,
        attemptCount: Int,
        wasRetryable: Bool
    ) {
        var stats = retryStats[operationName] ?? RetryStats(operationName: operationName)
        stats.recordFailure(error: error, attemptCount: attemptCount, wasRetryable: wasRetryable)
        retryStats[operationName] = stats
    }

    /// Get statistics for analytics
    func getStatistics() -> [String: RetryStats] {
        return retryStats
    }

    /// Clear statistics
    func clearStatistics() {
        retryStats.removeAll()
    }
}

/// Statistics for retry operations
struct RetryStats {
    let operationName: String
    var successCount: Int = 0
    var failureCount: Int = 0
    var totalAttempts: Int = 0
    var retriedAttempts: Int = 0
    var totalDuration: TimeInterval = 0
    var errorTypes: [String: Int] = [:]

    init(operationName: String) {
        self.operationName = operationName
    }

    mutating func recordSuccess(attemptCount: Int, duration: TimeInterval) {
        successCount += 1
        totalAttempts += attemptCount
        if attemptCount > 1 {
            retriedAttempts += (attemptCount - 1)
        }
        totalDuration += duration
    }

    mutating func recordFailure(error: Error, attemptCount: Int, wasRetryable: Bool) {
        failureCount += 1
        totalAttempts += attemptCount

        // Track error types (privacy-preserving)
        let errorType = String(describing: type(of: error))
        errorTypes[errorType, default: 0] += 1
    }

    var successRate: Double {
        let total = successCount + failureCount
        return total > 0 ? Double(successCount) / Double(total) : 0
    }

    var averageAttempts: Double {
        let total = successCount + failureCount
        return total > 0 ? Double(totalAttempts) / Double(total) : 0
    }

    var averageDuration: TimeInterval {
        return successCount > 0 ? totalDuration / Double(successCount) : 0
    }
}

// MARK: - Convenience Extensions

extension RetryManager {
    /// Retry a network operation (3 attempts, 1s base delay)
    func retryNetwork<T>(
        operationName: String? = nil,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await retry(
            config: .network,
            operationName: operationName,
            operation: operation
        )
    }

    /// Retry a critical operation (5 attempts, 0.5s base delay)
    func retryCritical<T>(
        operationName: String? = nil,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await retry(
            config: .critical,
            operationName: operationName,
            operation: operation
        )
    }

    /// Quick retry (2 attempts, 0.5s base delay)
    func retryQuick<T>(
        operationName: String? = nil,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await retry(
            config: .quick,
            operationName: operationName,
            operation: operation
        )
    }
}
