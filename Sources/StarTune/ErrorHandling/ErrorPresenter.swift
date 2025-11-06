//
//  ErrorPresenter.swift
//  StarTune
//
//  User-friendly error presentation with recovery suggestions
//

import SwiftUI

/// Protocol for presenting errors to users
protocol ErrorPresenting {
    func present(_ error: Error)
}

/// SwiftUI view for presenting errors
struct ErrorAlert: Identifiable {
    let id = UUID()
    let error: Error
    let title: String
    let message: String
    let recoverySuggestion: String?
    let recoveryActions: [RecoveryAction]

    init(error: Error) {
        self.error = error

        if let userFriendlyError = error as? UserFriendlyError {
            self.title = userFriendlyError.title
            self.message = userFriendlyError.message
            self.recoverySuggestion = userFriendlyError.recoverySuggestion
            self.recoveryActions = userFriendlyError.recoverySuggestions
        } else {
            self.title = "Error"
            self.message = error.localizedDescription
            self.recoverySuggestion = nil
            self.recoveryActions = []
        }

        // Record error for analytics
        recordError(error, userAction: "error_presented")
    }

    /// Create an Alert view
    func makeAlert() -> Alert {
        if let suggestion = recoverySuggestion {
            return Alert(
                title: Text(title),
                message: Text("\(message)\n\n💡 \(suggestion)"),
                dismissButton: .default(Text("OK"))
            )
        } else {
            return Alert(
                title: Text(title),
                message: Text(message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

/// View modifier for handling errors with alerts
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: Error?

    func body(content: Content) -> some View {
        content
            .alert(item: Binding(
                get: { error.map { ErrorAlert(error: $0) } },
                set: { _ in error = nil }
            )) { errorAlert in
                errorAlert.makeAlert()
            }
    }
}

extension View {
    /// Present errors as alerts with user-friendly messages
    func errorAlert(_ error: Binding<Error?>) -> some View {
        modifier(ErrorAlertModifier(error: error))
    }
}

// MARK: - Error Handling State

/// Observable state for error handling in SwiftUI views
@MainActor
class ErrorHandler: ObservableObject {
    @Published var currentError: Error?
    @Published var isShowingError = false

    /// Present an error to the user
    func handle(_ error: Error) {
        recordError(error, userAction: "error_displayed")
        currentError = error
        isShowingError = true
    }

    /// Clear current error
    func clearError() {
        currentError = nil
        isShowingError = false
    }

    /// Handle error with automatic retry option
    func handleWithRetry(_ error: Error, retryAction: @escaping () async -> Void) {
        if let retryableError = error as? RetryableError, retryableError.isRetryable {
            // Could show retry button here
            handle(error)
        } else {
            handle(error)
        }
    }
}

// MARK: - Console Error Presenter (for debugging)

/// Console-based error presenter for debugging
struct ConsoleErrorPresenter: ErrorPresenting {
    func present(_ error: Error) {
        print("\n" + String(repeating: "=", count: 60))
        print("❌ ERROR OCCURRED")
        print(String(repeating: "=", count: 60))

        if let userFriendlyError = error as? UserFriendlyError {
            print("📋 Title: \(userFriendlyError.title)")
            print("💬 Message: \(userFriendlyError.message)")
            if let suggestion = userFriendlyError.recoverySuggestion {
                print("💡 Recovery: \(suggestion)")
            }
        } else {
            print("Error: \(error.localizedDescription)")
        }

        if let appError = error as? AppError, appError.isRetryable {
            print("🔄 This error is retryable")
        }

        print(String(repeating: "=", count: 60) + "\n")
    }
}
