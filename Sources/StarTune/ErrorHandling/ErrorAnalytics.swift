//
//  ErrorAnalytics.swift
//  StarTune
//
//  Privacy-preserving error analytics for monitoring app health
//

import Foundation

/// Privacy-preserving error analytics
/// Tracks error patterns without collecting sensitive user data
actor ErrorAnalytics {
    /// Shared instance
    static let shared = ErrorAnalytics()

    /// Analytics data
    private var analytics: AnalyticsData = AnalyticsData()

    /// Maximum number of error events to store
    private let maxErrorEvents = 100

    private init() {}

    /// Record an error event
    func recordError(_ error: Error, context: ErrorContext? = nil) {
        let event = ErrorEvent(error: error, context: context)
        analytics.recordError(event)

        // Trim old events if needed
        if analytics.errorEvents.count > maxErrorEvents {
            analytics.errorEvents.removeFirst(analytics.errorEvents.count - maxErrorEvents)
        }

        #if DEBUG
        print("📊 Error recorded: \(event.errorType) in \(event.location ?? "unknown")")
        #endif
    }

    /// Record error resolution
    func recordResolution(_ error: Error, method: ResolutionMethod) {
        let errorType = getErrorType(error)
        analytics.recordResolution(errorType: errorType, method: method)

        #if DEBUG
        print("✅ Error resolved: \(errorType) via \(method)")
        #endif
    }

    /// Get analytics summary
    func getSummary() -> AnalyticsSummary {
        return analytics.getSummary()
    }

    /// Get detailed analytics (for debugging)
    func getDetailedAnalytics() -> AnalyticsData {
        return analytics
    }

    /// Clear all analytics data
    func clearAnalytics() {
        analytics = AnalyticsData()
    }

    /// Export analytics as privacy-preserving JSON
    func exportAnalytics() -> String {
        let summary = analytics.getSummary()
        return summary.toJSON()
    }

    // MARK: - Private Helpers

    private func getErrorType(_ error: Error) -> String {
        if let appError = error as? AppError {
            switch appError {
            case .networkError(let netError):
                return "Network.\(String(describing: netError).components(separatedBy: "(").first ?? "Unknown")"
            case .authorizationError(let authError):
                return "Authorization.\(String(describing: authError))"
            case .resourceError(let resError):
                return "Resource.\(String(describing: resError).components(separatedBy: "(").first ?? "Unknown")"
            case .operationError(let opError):
                return "Operation.\(String(describing: opError).components(separatedBy: "(").first ?? "Unknown")"
            case .systemError(let sysError):
                return "System.\(String(describing: sysError).components(separatedBy: "(").first ?? "Unknown")"
            case .unknown:
                return "Unknown"
            }
        }
        return String(describing: type(of: error))
    }
}

// MARK: - Data Structures

/// Context information for an error (privacy-preserving)
struct ErrorContext {
    /// Location in code (file:line or function name)
    let location: String?

    /// Operation being performed
    let operation: String?

    /// User action that triggered the error
    let userAction: String?

    /// Additional metadata (no PII)
    let metadata: [String: String]?

    init(
        location: String? = nil,
        operation: String? = nil,
        userAction: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.location = location
        self.operation = operation
        self.userAction = userAction
        self.metadata = metadata
    }
}

/// Error event (privacy-preserving)
struct ErrorEvent {
    let id = UUID()
    let timestamp: Date
    let errorType: String
    let location: String?
    let operation: String?
    let userAction: String?
    let isRetryable: Bool

    init(error: Error, context: ErrorContext?) {
        self.timestamp = Date()
        self.location = context?.location
        self.operation = context?.operation
        self.userAction = context?.userAction

        // Determine error type without exposing sensitive data
        if let appError = error as? AppError {
            self.isRetryable = appError.isRetryable
            switch appError {
            case .networkError(let netError):
                self.errorType = "Network.\(String(describing: netError).components(separatedBy: "(").first ?? "Unknown")"
            case .authorizationError(let authError):
                self.errorType = "Authorization.\(String(describing: authError))"
            case .resourceError(let resError):
                self.errorType = "Resource.\(String(describing: resError).components(separatedBy: "(").first ?? "Unknown")"
            case .operationError(let opError):
                self.errorType = "Operation.\(String(describing: opError).components(separatedBy: "(").first ?? "Unknown")"
            case .systemError(let sysError):
                self.errorType = "System.\(String(describing: sysError).components(separatedBy: "(").first ?? "Unknown")"
            case .unknown:
                self.errorType = "Unknown"
            }
        } else {
            self.errorType = String(describing: type(of: error))
            self.isRetryable = (error as? RetryableError)?.isRetryable ?? false
        }
    }
}

/// Method used to resolve an error
enum ResolutionMethod: String, Codable {
    case retry = "retry"
    case userAction = "user_action"
    case automatic = "automatic"
    case manual = "manual"
    case ignored = "ignored"
}

/// Analytics data storage
struct AnalyticsData {
    /// All error events
    var errorEvents: [ErrorEvent] = []

    /// Error type counts
    var errorCounts: [String: Int] = [:]

    /// Resolution counts by error type and method
    var resolutionCounts: [String: [ResolutionMethod: Int]] = [:]

    /// Error rate by hour (for pattern detection)
    var errorsByHour: [Int: Int] = [:]

    mutating func recordError(_ event: ErrorEvent) {
        errorEvents.append(event)
        errorCounts[event.errorType, default: 0] += 1

        // Record by hour for pattern detection
        let hour = Calendar.current.component(.hour, from: event.timestamp)
        errorsByHour[hour, default: 0] += 1
    }

    mutating func recordResolution(errorType: String, method: ResolutionMethod) {
        if resolutionCounts[errorType] == nil {
            resolutionCounts[errorType] = [:]
        }
        resolutionCounts[errorType]?[method, default: 0] += 1
    }

    func getSummary() -> AnalyticsSummary {
        let now = Date()
        let last24Hours = errorEvents.filter { now.timeIntervalSince($0.timestamp) < 86400 }
        let last7Days = errorEvents.filter { now.timeIntervalSince($0.timestamp) < 604800 }

        // Top error types
        let topErrors = errorCounts.sorted { $0.value > $1.value }
            .prefix(10)
            .map { ErrorTypeSummary(type: $0.key, count: $0.value) }

        // Error rate
        let totalErrors = errorEvents.count
        let retryableErrors = errorEvents.filter { $0.isRetryable }.count

        // Most common operations with errors
        let operationCounts = Dictionary(grouping: errorEvents) { $0.operation ?? "unknown" }
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { OperationSummary(operation: $0.key, errorCount: $0.value) }

        return AnalyticsSummary(
            totalErrors: totalErrors,
            errorsLast24Hours: last24Hours.count,
            errorsLast7Days: last7Days.count,
            retryableErrorsPercentage: totalErrors > 0 ? Double(retryableErrors) / Double(totalErrors) : 0,
            topErrorTypes: topErrors,
            topErrorOperations: operationCounts,
            resolutionStats: resolutionCounts
        )
    }
}

/// Privacy-preserving analytics summary
struct AnalyticsSummary: Codable {
    let totalErrors: Int
    let errorsLast24Hours: Int
    let errorsLast7Days: Int
    let retryableErrorsPercentage: Double
    let topErrorTypes: [ErrorTypeSummary]
    let topErrorOperations: [OperationSummary]
    let resolutionStats: [String: [ResolutionMethod: Int]]

    func toJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        if let data = try? encoder.encode(self),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return "{}"
    }
}

struct ErrorTypeSummary: Codable {
    let type: String
    let count: Int
}

struct OperationSummary: Codable {
    let operation: String
    let errorCount: Int
}

// MARK: - Convenience Extensions

extension ErrorAnalytics {
    /// Record error with automatic context
    func recordError(
        _ error: Error,
        operation: String? = nil,
        userAction: String? = nil,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) {
        let location = "\(URL(fileURLWithPath: file).lastPathComponent):\(line)"
        let context = ErrorContext(
            location: location,
            operation: operation,
            userAction: userAction
        )
        Task {
            await recordError(error, context: context)
        }
    }
}

// MARK: - Global Error Recording Helper

/// Global function for convenient error recording
func recordError(
    _ error: Error,
    operation: String? = nil,
    userAction: String? = nil,
    file: String = #file,
    line: Int = #line,
    function: String = #function
) {
    Task {
        let location = "\(URL(fileURLWithPath: file).lastPathComponent):\(line)"
        let context = ErrorContext(
            location: location,
            operation: operation,
            userAction: userAction
        )
        await ErrorAnalytics.shared.recordError(error, context: context)
    }
}
