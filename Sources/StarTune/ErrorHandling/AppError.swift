//
//  AppError.swift
//  StarTune
//
//  Comprehensive error types for typed error propagation
//

import Foundation

/// Protocol for errors that can be retried
protocol RetryableError: Error {
    var isRetryable: Bool { get }
    var retryDelay: TimeInterval { get }
}

/// Protocol for errors that provide user-friendly messages
protocol UserFriendlyError: Error {
    var title: String { get }
    var message: String { get }
    var recoverySuggestion: String? { get }
    var recoverySuggestions: [RecoveryAction] { get }
}

/// Recovery action that users can take
struct RecoveryAction: Identifiable {
    let id = UUID()
    let title: String
    let action: () async -> Void

    init(title: String, action: @escaping () async -> Void) {
        self.title = title
        self.action = action
    }
}

/// Main app error type with comprehensive error categorization
enum AppError: Error {
    // Network-related errors
    case networkError(NetworkError)

    // Authorization errors
    case authorizationError(AuthorizationError)

    // Resource errors
    case resourceError(ResourceError)

    // Operation errors
    case operationError(OperationError)

    // System errors
    case systemError(SystemError)

    // Unknown error
    case unknown(Error)

    /// Convenience initializer from any error
    static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        // Try to categorize the error
        let nsError = error as NSError

        // Network errors
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return .networkError(.noConnection)
            case NSURLErrorTimedOut:
                return .networkError(.timeout)
            case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                return .networkError(.serverUnavailable)
            default:
                return .networkError(.requestFailed(error))
            }
        }

        return .unknown(error)
    }
}

// MARK: - Network Errors

enum NetworkError: Error {
    case noConnection
    case timeout
    case serverUnavailable
    case rateLimited
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
}

extension NetworkError: RetryableError {
    var isRetryable: Bool {
        switch self {
        case .noConnection, .timeout, .serverUnavailable, .rateLimited:
            return true
        case .requestFailed, .invalidResponse, .decodingFailed:
            return false
        }
    }

    var retryDelay: TimeInterval {
        switch self {
        case .rateLimited:
            return 10.0 // Wait longer for rate limits
        case .noConnection, .serverUnavailable:
            return 2.0
        case .timeout:
            return 1.0
        default:
            return 0.5
        }
    }
}

extension NetworkError: UserFriendlyError {
    var title: String {
        switch self {
        case .noConnection:
            return "No Internet Connection"
        case .timeout:
            return "Request Timed Out"
        case .serverUnavailable:
            return "Service Unavailable"
        case .rateLimited:
            return "Too Many Requests"
        case .requestFailed:
            return "Network Error"
        case .invalidResponse:
            return "Invalid Response"
        case .decodingFailed:
            return "Data Error"
        }
    }

    var message: String {
        switch self {
        case .noConnection:
            return "Unable to connect to the internet. Please check your connection and try again."
        case .timeout:
            return "The request took too long to complete. Please try again."
        case .serverUnavailable:
            return "The Apple Music service is temporarily unavailable. Please try again later."
        case .rateLimited:
            return "You've made too many requests. Please wait a moment and try again."
        case .requestFailed(let error):
            return "Network request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "Received an unexpected response from the server."
        case .decodingFailed(let error):
            return "Failed to process server response: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Check your internet connection and try again"
        case .timeout, .serverUnavailable:
            return "Try again in a few moments"
        case .rateLimited:
            return "Wait a minute before trying again"
        case .requestFailed, .invalidResponse, .decodingFailed:
            return "If the problem persists, please restart the app"
        }
    }

    var recoverySuggestions: [RecoveryAction] {
        []
    }
}

// MARK: - Authorization Errors

enum AuthorizationError: Error {
    case notAuthorized
    case restricted
    case denied
    case noSubscription
}

extension AuthorizationError: UserFriendlyError {
    var title: String {
        switch self {
        case .notAuthorized:
            return "Authorization Required"
        case .restricted:
            return "Access Restricted"
        case .denied:
            return "Permission Denied"
        case .noSubscription:
            return "Subscription Required"
        }
    }

    var message: String {
        switch self {
        case .notAuthorized:
            return "StarTune needs permission to access Apple Music. Please grant authorization in the prompt."
        case .restricted:
            return "Access to Apple Music is restricted on this device."
        case .denied:
            return "You've denied permission to access Apple Music. StarTune needs this permission to add songs to your favorites."
        case .noSubscription:
            return "An active Apple Music subscription is required to add songs to your favorites."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notAuthorized:
            return "Click 'Request Authorization' to grant permission"
        case .restricted:
            return "Check Screen Time or parental control settings"
        case .denied:
            return "Go to System Settings → Privacy → Media & Apple Music to grant permission"
        case .noSubscription:
            return "Subscribe to Apple Music to use this feature"
        }
    }

    var recoverySuggestions: [RecoveryAction] {
        []
    }
}

// MARK: - Resource Errors

enum ResourceError: Error {
    case notFound(String)
    case alreadyExists
    case unavailable
}

extension ResourceError: UserFriendlyError {
    var title: String {
        switch self {
        case .notFound:
            return "Not Found"
        case .alreadyExists:
            return "Already Exists"
        case .unavailable:
            return "Unavailable"
        }
    }

    var message: String {
        switch self {
        case .notFound(let resource):
            return "The \(resource) could not be found in the Apple Music catalog."
        case .alreadyExists:
            return "This item already exists."
        case .unavailable:
            return "This resource is currently unavailable."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notFound:
            return "Try playing a different song"
        case .alreadyExists:
            return nil
        case .unavailable:
            return "Try again later"
        }
    }

    var recoverySuggestions: [RecoveryAction] {
        []
    }
}

// MARK: - Operation Errors

enum OperationError: Error {
    case cancelled
    case failed(String)
    case timeout
    case invalidState(String)
}

extension OperationError: UserFriendlyError {
    var title: String {
        switch self {
        case .cancelled:
            return "Cancelled"
        case .failed:
            return "Operation Failed"
        case .timeout:
            return "Timeout"
        case .invalidState:
            return "Invalid State"
        }
    }

    var message: String {
        switch self {
        case .cancelled:
            return "The operation was cancelled."
        case .failed(let reason):
            return "The operation failed: \(reason)"
        case .timeout:
            return "The operation took too long to complete."
        case .invalidState(let reason):
            return "Cannot perform this operation: \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .cancelled:
            return nil
        case .failed, .timeout:
            return "Try again"
        case .invalidState:
            return "Please check the current state and try again"
        }
    }

    var recoverySuggestions: [RecoveryAction] {
        []
    }
}

// MARK: - System Errors

enum SystemError: Error {
    case musicAppNotRunning
    case musicAppNotResponding
    case scriptError(String)
    case permissionDenied(String)
}

extension SystemError: UserFriendlyError {
    var title: String {
        switch self {
        case .musicAppNotRunning:
            return "Music App Not Running"
        case .musicAppNotResponding:
            return "Music App Not Responding"
        case .scriptError:
            return "Script Error"
        case .permissionDenied:
            return "Permission Denied"
        }
    }

    var message: String {
        switch self {
        case .musicAppNotRunning:
            return "The Music app is not running. Please open the Music app to use StarTune."
        case .musicAppNotResponding:
            return "The Music app is not responding. Please wait a moment or restart the Music app."
        case .scriptError(let error):
            return "Failed to communicate with Music app: \(error)"
        case .permissionDenied(let reason):
            return "Permission denied: \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .musicAppNotRunning:
            return "Launch the Music app and try again"
        case .musicAppNotResponding:
            return "Restart the Music app"
        case .scriptError:
            return "Grant StarTune permission to control Music in System Settings"
        case .permissionDenied:
            return "Check System Settings → Privacy & Security → Automation"
        }
    }

    var recoverySuggestions: [RecoveryAction] {
        []
    }
}

// MARK: - AppError UserFriendlyError Conformance

extension AppError: UserFriendlyError {
    var title: String {
        switch self {
        case .networkError(let error):
            return error.title
        case .authorizationError(let error):
            return error.title
        case .resourceError(let error):
            return error.title
        case .operationError(let error):
            return error.title
        case .systemError(let error):
            return error.title
        case .unknown:
            return "Unexpected Error"
        }
    }

    var message: String {
        switch self {
        case .networkError(let error):
            return error.message
        case .authorizationError(let error):
            return error.message
        case .resourceError(let error):
            return error.message
        case .operationError(let error):
            return error.message
        case .systemError(let error):
            return error.message
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkError(let error):
            return error.recoverySuggestion
        case .authorizationError(let error):
            return error.recoverySuggestion
        case .resourceError(let error):
            return error.recoverySuggestion
        case .operationError(let error):
            return error.recoverySuggestion
        case .systemError(let error):
            return error.recoverySuggestion
        case .unknown:
            return "Please try restarting the app"
        }
    }

    var recoverySuggestions: [RecoveryAction] {
        switch self {
        case .networkError(let error):
            return error.recoverySuggestions
        case .authorizationError(let error):
            return error.recoverySuggestions
        case .resourceError(let error):
            return error.recoverySuggestions
        case .operationError(let error):
            return error.recoverySuggestions
        case .systemError(let error):
            return error.recoverySuggestions
        case .unknown:
            return []
        }
    }
}

// MARK: - AppError RetryableError Conformance

extension AppError: RetryableError {
    var isRetryable: Bool {
        switch self {
        case .networkError(let error):
            return error.isRetryable
        case .authorizationError:
            return false
        case .resourceError:
            return false
        case .operationError(let error):
            if case .timeout = error {
                return true
            }
            return false
        case .systemError(let error):
            if case .musicAppNotResponding = error {
                return true
            }
            return false
        case .unknown:
            return false
        }
    }

    var retryDelay: TimeInterval {
        switch self {
        case .networkError(let error):
            return error.retryDelay
        case .operationError(.timeout):
            return 1.0
        case .systemError(.musicAppNotResponding):
            return 2.0
        default:
            return 0.5
        }
    }
}
