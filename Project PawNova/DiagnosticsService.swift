//
//  DiagnosticsService.swift
//  Project PawNova
//
//  Diagnostics, logging, and crash reporting utilities
//

import SwiftUI
import os.log

// MARK: - Diagnostics Service

@Observable
@MainActor
final class DiagnosticsService {
    static let shared = DiagnosticsService()

    private let logger = Logger(subsystem: "com.pawnova.app", category: "diagnostics")
    private var logEntries: [LogEntry] = []
    private let maxLogEntries = 500

    private init() {
        logSystemInfo()
    }

    // MARK: - Log Entry

    struct LogEntry: Identifiable, Codable {
        let id: UUID
        let timestamp: Date
        let level: LogLevel
        let category: String
        let message: String

        init(level: LogLevel, category: String, message: String) {
            self.id = UUID()
            self.timestamp = Date()
            self.level = level
            self.category = category
            self.message = message
        }
    }

    enum LogLevel: String, Codable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARN"
        case error = "ERROR"
        case critical = "CRITICAL"

        var emoji: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .critical: return "🔥"
            }
        }
    }

    // MARK: - Logging

    func log(_ level: LogLevel, category: String, message: String) {
        let entry = LogEntry(level: level, category: category, message: message)

        // Add to in-memory log
        logEntries.append(entry)
        if logEntries.count > maxLogEntries {
            logEntries.removeFirst(logEntries.count - maxLogEntries)
        }

        // Also log to system (visible in Console.app)
        let logMessage = "[\(category)] \(message)"
        switch level {
        case .debug:
            logger.debug("\(logMessage)")
        case .info:
            logger.info("\(logMessage)")
        case .warning:
            logger.warning("\(logMessage)")
        case .error:
            logger.error("\(logMessage)")
        case .critical:
            logger.critical("\(logMessage)")
        }

        #if DEBUG
        print("\(entry.level.emoji) \(logMessage)")
        #endif
    }

    func debug(_ message: String, category: String = "App") {
        log(.debug, category: category, message: message)
    }

    func info(_ message: String, category: String = "App") {
        log(.info, category: category, message: message)
    }

    func warning(_ message: String, category: String = "App") {
        log(.warning, category: category, message: message)
    }

    func error(_ message: String, category: String = "App") {
        log(.error, category: category, message: message)
    }

    func critical(_ message: String, category: String = "App") {
        log(.critical, category: category, message: message)
    }

    // MARK: - System Info

    private func logSystemInfo() {
        let device = UIDevice.current
        let bundle = Bundle.main

        info("App Version: \(bundle.appVersion) (\(bundle.buildNumber))", category: "System")
        info("iOS Version: \(device.systemVersion)", category: "System")
        info("Device: \(device.model)", category: "System")
        info("Device Name: \(device.name)", category: "System")
    }

    // MARK: - Export

    /// Generate diagnostic report for support
    func generateReport() -> String {
        var report = """
        ==========================================
        PawNova Diagnostic Report
        Generated: \(Date().ISO8601Format())
        ==========================================

        DEVICE INFO
        -----------
        """

        let device = UIDevice.current
        let bundle = Bundle.main

        report += """

        App Version: \(bundle.appVersion) (\(bundle.buildNumber))
        iOS Version: \(device.systemVersion)
        Device Model: \(device.model)
        Device Name: \(device.name)
        System Uptime: \(ProcessInfo.processInfo.systemUptime.formatted()) seconds

        NETWORK STATUS
        --------------
        Connected: \(NetworkMonitor.shared.isConnected)
        Connection Type: \(NetworkMonitor.shared.connectionType)

        APP STATE
        ---------
        Demo Mode: \(FalService.shared.demoMode)

        RECENT LOGS (\(logEntries.count) entries)
        ------------------------------------------

        """

        // Add last 100 log entries
        let recentLogs = logEntries.suffix(100)
        for entry in recentLogs {
            let timestamp = entry.timestamp.formatted(date: .omitted, time: .standard)
            report += "[\(timestamp)] \(entry.level.rawValue) [\(entry.category)] \(entry.message)\n"
        }

        report += """

        ==========================================
        End of Report
        ==========================================
        """

        return report
    }

    /// Share diagnostic report
    func shareReport() -> URL? {
        let report = generateReport()
        let fileName = "pawnova_diagnostics_\(Date().ISO8601Format()).txt"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try report.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            self.error("Failed to write diagnostic report: \(error.localizedDescription)", category: "Diagnostics")
            return nil
        }
    }

    /// Clear all logs
    func clearLogs() {
        logEntries.removeAll()
        info("Logs cleared", category: "Diagnostics")
    }
}

// MARK: - Bundle Extension

extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}

// MARK: - Diagnostics View

struct DiagnosticsView: View {
    @State private var diagnostics = DiagnosticsService.shared
    @State private var showShareSheet = false
    @State private var reportURL: URL?

    var body: some View {
        List {
            // Device Info Section
            Section("Device Info") {
                InfoRow(label: "App Version", value: Bundle.main.appVersion)
                InfoRow(label: "Build", value: Bundle.main.buildNumber)
                InfoRow(label: "iOS Version", value: UIDevice.current.systemVersion)
                InfoRow(label: "Device", value: UIDevice.current.model)
            }
            .listRowBackground(Color.pawCard)

            // Network Section
            Section("Network") {
                InfoRow(
                    label: "Status",
                    value: NetworkMonitor.shared.isConnected ? "Connected" : "Offline",
                    valueColor: NetworkMonitor.shared.isConnected ? .pawSuccess : .pawError
                )
                InfoRow(label: "Type", value: "\(NetworkMonitor.shared.connectionType)")
            }
            .listRowBackground(Color.pawCard)

            // App State Section
            Section("App State") {
                InfoRow(
                    label: "Demo Mode",
                    value: FalService.shared.demoMode ? "ON" : "OFF",
                    valueColor: FalService.shared.demoMode ? .pawWarning : .pawSuccess
                )
            }
            .listRowBackground(Color.pawCard)

            // Actions Section
            Section("Actions") {
                Button {
                    exportReport()
                } label: {
                    Label("Export Diagnostic Report", systemImage: "square.and.arrow.up")
                        .foregroundColor(.pawPrimary)
                }

                Button(role: .destructive) {
                    diagnostics.clearLogs()
                } label: {
                    Label("Clear Logs", systemImage: "trash")
                        .foregroundColor(.pawError)
                }
            }
            .listRowBackground(Color.pawCard)

            // Info Section
            Section {
                Text("Diagnostic reports help our support team troubleshoot issues. They include device info, app state, and recent activity logs. No personal data or videos are included.")
                    .font(.caption)
                    .foregroundColor(.pawTextSecondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.pawBackground)
        .navigationTitle("Diagnostics")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showShareSheet) {
            if let url = reportURL {
                ShareSheet(items: [url])
            }
        }
    }

    private func exportReport() {
        if let url = diagnostics.shareReport() {
            reportURL = url
            showShareSheet = true
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .pawTextSecondary

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.pawTextPrimary)
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Crash Reporting Info

/*
 CRASH REPORTING OPTIONS:

 For production apps, integrate one of these services:

 1. FIREBASE CRASHLYTICS (Recommended - Free)
    - Real-time crash reports
    - Custom logging with `Crashlytics.log()`
    - User-level crash tracking
    - Integration: Add Firebase SDK via SPM

    ```swift
    import FirebaseCrashlytics

    // In app init:
    FirebaseApp.configure()

    // Log non-fatal errors:
    Crashlytics.crashlytics().record(error: error)

    // Custom keys for context:
    Crashlytics.crashlytics().setCustomValue(userId, forKey: "user_id")
    ```

 2. SENTRY (Free tier available)
    - Errors + Performance monitoring
    - Release tracking
    - Integration: `sentry-cocoa` SPM package

 3. BUGSNAG
    - Similar to Sentry
    - Good React Native support if cross-platform

 4. APPLE'S BUILT-IN (App Store Connect)
    - Crashes tab in App Store Connect
    - Delayed (24-48 hours)
    - Limited context
    - Free, no integration needed

 To view Apple crash reports:
 1. App Store Connect > Your App > Analytics > Crashes
 2. Xcode > Window > Organizer > Crashes

 RECOMMENDED SETUP:
 - Development: Use DiagnosticsService + Console.app
 - TestFlight: Add Firebase Crashlytics for beta testing
 - Production: Firebase Crashlytics + App Store Connect
*/

#Preview {
    NavigationStack {
        DiagnosticsView()
    }
}
