//
//  ErrorHandling.swift
//  Project PawNova
//
//  Centralized error handling, network monitoring, and user-friendly error presentation
//

import SwiftUI
import Network
import os.log
import FirebaseCrashlytics

// MARK: - App-Wide Error Types

/// Unified error type for the entire app
enum PawNovaError: LocalizedError {
    // Network
    case noInternet
    case serverUnreachable
    case timeout
    case rateLimited

    // API
    case apiKeyMissing
    case apiKeyInvalid
    case generationFailed(reason: String)
    case contentBlocked

    // Store
    case purchaseFailed(reason: String)
    case purchaseCancelled
    case subscriptionExpired

    // Data
    case saveFailed
    case loadFailed
    case permissionDenied(type: String)

    // Generic
    case unknown(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .noInternet:
            return "No internet connection"
        case .serverUnreachable:
            return "Unable to reach server"
        case .timeout:
            return "Request timed out"
        case .rateLimited:
            return "Too many requests. Please wait a moment."
        case .apiKeyMissing:
            return "Service not configured"
        case .apiKeyInvalid:
            return "Service authentication failed"
        case .generationFailed(let reason):
            return "Video generation failed: \(reason)"
        case .contentBlocked:
            return "Content not allowed by our guidelines"
        case .purchaseFailed(let reason):
            return "Purchase failed: \(reason)"
        case .purchaseCancelled:
            return "Purchase was cancelled"
        case .subscriptionExpired:
            return "Your subscription has expired"
        case .saveFailed:
            return "Failed to save data"
        case .loadFailed:
            return "Failed to load data"
        case .permissionDenied(let type):
            return "\(type) permission required"
        case .unknown(let underlying):
            return underlying.localizedDescription
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .noInternet:
            return "Check your internet connection and try again."
        case .serverUnreachable:
            return "Our servers may be temporarily unavailable. Please try again later."
        case .timeout:
            return "The request took too long. Try with a simpler prompt."
        case .rateLimited:
            return "You've made too many requests. Wait a few seconds and try again."
        case .apiKeyMissing, .apiKeyInvalid:
            return "Please contact support if this persists."
        case .generationFailed:
            return "Try a different prompt or select another AI model."
        case .contentBlocked:
            return "Please modify your prompt to follow our content guidelines."
        case .purchaseFailed:
            return "Check your payment method in Settings."
        case .purchaseCancelled:
            return nil
        case .subscriptionExpired:
            return "Renew your subscription to continue."
        case .saveFailed, .loadFailed:
            return "Try again. If the problem persists, restart the app."
        case .permissionDenied(let type):
            return "Go to Settings > PawNova to enable \(type) access."
        case .unknown:
            return "Please try again or contact support."
        }
    }

    var isRetryable: Bool {
        switch self {
        case .noInternet, .serverUnreachable, .timeout, .rateLimited:
            return true
        case .saveFailed, .loadFailed:
            return true
        case .generationFailed:
            return true
        default:
            return false
        }
    }
}

// MARK: - Network Monitor

@Observable
@MainActor
class NetworkMonitor {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    var isConnected = true
    var connectionType: ConnectionType = .unknown

    enum ConnectionType {
        case wifi
        case cellular
        case wired
        case unknown
    }

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isConnected = path.status == .satisfied
                self.connectionType = self.getConnectionType(path)
            }
        }
        monitor.start(queue: queue)
    }

    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .wired }
        return .unknown
    }

    func checkConnection() throws {
        guard isConnected else {
            throw PawNovaError.noInternet
        }
    }
}

// MARK: - Error Logger

class ErrorLogger {
    static let shared = ErrorLogger()
    private let logger = Logger(subsystem: "com.pawnova.app", category: "errors")

    private init() {}

    func log(_ error: Error, context: String? = nil) {
        let contextStr = context.map { "[\($0)] " } ?? ""

        if let pawError = error as? PawNovaError {
            logger.error("\(contextStr)PawNovaError: \(pawError.errorDescription ?? "Unknown")")
        } else if let falError = error as? FalServiceError {
            logger.error("\(contextStr)FalServiceError: \(falError.errorDescription ?? "Unknown")")
        } else {
            logger.error("\(contextStr)Error: \(error.localizedDescription)")
        }

        // Send to Firebase Crashlytics
        Crashlytics.crashlytics().log("\(contextStr)\(error.localizedDescription)")
        Crashlytics.crashlytics().record(error: error)

        #if DEBUG
        print("🔴 Error logged: \(contextStr)\(error.localizedDescription)")
        #endif
    }

    func logWarning(_ message: String, context: String? = nil) {
        let contextStr = context.map { "[\($0)] " } ?? ""
        logger.warning("\(contextStr)\(message)")

        // Send to Firebase Crashlytics
        Crashlytics.crashlytics().log("⚠️ \(contextStr)\(message)")

        #if DEBUG
        print("🟡 Warning: \(contextStr)\(message)")
        #endif
    }

    func logInfo(_ message: String, context: String? = nil) {
        let contextStr = context.map { "[\($0)] " } ?? ""
        logger.info("\(contextStr)\(message)")

        #if DEBUG
        print("🔵 Info: \(contextStr)\(message)")
        #endif
    }
}

// MARK: - Retry Logic

struct RetryConfig: Sendable {
    let maxAttempts: Int
    let initialDelay: TimeInterval
    let maxDelay: TimeInterval
    let multiplier: Double

    static let `default` = RetryConfig(
        maxAttempts: 3,
        initialDelay: 1.0,
        maxDelay: 10.0,
        multiplier: 2.0
    )

    static let aggressive = RetryConfig(
        maxAttempts: 5,
        initialDelay: 0.5,
        maxDelay: 30.0,
        multiplier: 2.0
    )
}

func withRetry<T>(
    config: RetryConfig? = nil,
    operation: @escaping () async throws -> T
) async throws -> T {
    let resolvedConfig = config ?? RetryConfig(
        maxAttempts: 3,
        initialDelay: 1.0,
        maxDelay: 10.0,
        multiplier: 2.0
    )
    var lastError: Error?
    var delay = resolvedConfig.initialDelay

    for attempt in 1...resolvedConfig.maxAttempts {
        do {
            return try await operation()
        } catch {
            lastError = error

            // Check if error is retryable
            if let pawError = error as? PawNovaError, !pawError.isRetryable {
                throw error
            }

            // Don't retry on last attempt
            if attempt == resolvedConfig.maxAttempts {
                break
            }

            ErrorLogger.shared.logWarning(
                "Attempt \(attempt) failed, retrying in \(delay)s...",
                context: "Retry"
            )

            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            delay = min(delay * resolvedConfig.multiplier, resolvedConfig.maxDelay)
        }
    }

    throw lastError ?? PawNovaError.unknown(underlying: NSError(domain: "PawNova", code: -1))
}

// MARK: - Input Sanitization

enum InputSanitizer {
    /// Sanitize user prompts to prevent injection and ensure content safety
    static func sanitizePrompt(_ input: String) -> String {
        var sanitized = input

        // Trim whitespace
        sanitized = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)

        // Limit length
        if sanitized.count > 500 {
            sanitized = String(sanitized.prefix(500))
        }

        // Remove potential injection patterns (basic)
        let dangerousPatterns = [
            "ignore previous",
            "disregard instructions",
            "system prompt",
            "<script>",
            "javascript:",
        ]

        for pattern in dangerousPatterns {
            sanitized = sanitized.replacingOccurrences(
                of: pattern,
                with: "",
                options: .caseInsensitive
            )
        }

        // Remove excessive special characters
        let allowedCharacters = CharacterSet.alphanumerics
            .union(.whitespaces)
            .union(CharacterSet(charactersIn: ".,!?'-"))

        sanitized = sanitized.unicodeScalars
            .filter { allowedCharacters.contains($0) || $0.value > 127 } // Allow emojis/unicode
            .map { Character($0) }
            .map { String($0) }
            .joined()

        return sanitized
    }

    /// Check if prompt contains potentially inappropriate content
    static func containsBlockedContent(_ input: String) -> Bool {
        let lowercased = input.lowercased()

        // Basic blocklist (expand as needed)
        let blockedTerms = [
            "violence", "gore", "blood",
            "nude", "naked", "explicit",
            "hate", "racist", "discriminat",
        ]

        return blockedTerms.contains { lowercased.contains($0) }
    }
}

// MARK: - Error Alert View Modifier

struct ErrorAlertModifier: ViewModifier {
    @Binding var error: PawNovaError?
    let onRetry: (() -> Void)?

    func body(content: Content) -> some View {
        content
            .alert(
                "Something Went Wrong",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    error = nil
                }

                if let error = error, error.isRetryable, let retry = onRetry {
                    Button("Try Again") {
                        self.error = nil
                        retry()
                    }
                }
            } message: {
                if let error = error {
                    VStack {
                        Text(error.errorDescription ?? "An unknown error occurred")
                        if let suggestion = error.recoverySuggestion {
                            Text(suggestion)
                                .font(.caption)
                        }
                    }
                }
            }
    }
}

extension View {
    func errorAlert(error: Binding<PawNovaError?>, onRetry: (() -> Void)? = nil) -> some View {
        modifier(ErrorAlertModifier(error: error, onRetry: onRetry))
    }
}

// MARK: - Offline Banner View

struct OfflineBanner: View {
    @State private var network = NetworkMonitor.shared

    var body: some View {
        if !network.isConnected {
            HStack {
                Image(systemName: "wifi.slash")
                Text("No Internet Connection")
                    .font(.caption.bold())
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.pawError)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
