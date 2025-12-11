//
//  SecureStorage.swift
//  Project PawNova
//
//  Secure storage using Keychain for sensitive data
//

import Foundation
import Security

// MARK: - Keychain Wrapper

enum KeychainError: LocalizedError {
    case duplicateEntry
    case unknown(OSStatus)
    case notFound
    case invalidData

    var errorDescription: String? {
        switch self {
        case .duplicateEntry: return "Item already exists in Keychain"
        case .unknown(let status): return "Keychain error: \(status)"
        case .notFound: return "Item not found in Keychain"
        case .invalidData: return "Invalid data format"
        }
    }
}

final class KeychainManager {
    static let shared = KeychainManager()

    private let service = "com.pawnova.app"

    private init() {}

    // MARK: - Generic Operations

    func save<T: Codable>(_ item: T, forKey key: String) throws {
        let data = try JSONEncoder().encode(item)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }

    func load<T: Codable>(forKey key: String) throws -> T {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.notFound
            }
            throw KeychainError.unknown(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }

    func exists(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false,
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}

// MARK: - Secure User Data

/// Stores sensitive user data securely in Keychain
@Observable
@MainActor
final class SecureUserData {
    static let shared = SecureUserData()

    private let keychain = KeychainManager.shared

    // Keys
    private let creditsKey = "user_credits"
    private let subscriptionKey = "subscription_status"
    private let userIdKey = "user_id"

    // Cached values (loaded from Keychain on init)
    private(set) var credits: Int = 0
    private(set) var isSubscribed: Bool = false
    private(set) var userId: String?

    private init() {
        loadFromKeychain()
    }

    // MARK: - Credits

    func setCredits(_ value: Int) {
        credits = max(0, value)
        saveToKeychain(credits, forKey: creditsKey)
    }

    func addCredits(_ amount: Int) {
        setCredits(credits + amount)
    }

    func deductCredits(_ amount: Int) -> Bool {
        guard credits >= amount else { return false }
        setCredits(credits - amount)
        return true
    }

    // MARK: - Subscription

    func setSubscribed(_ value: Bool) {
        isSubscribed = value
        saveToKeychain(value, forKey: subscriptionKey)
    }

    // MARK: - User ID

    func setUserId(_ id: String?) {
        userId = id
        if let id = id {
            saveToKeychain(id, forKey: userIdKey)
        } else {
            try? keychain.delete(forKey: userIdKey)
        }
    }

    // MARK: - Reset

    func resetAll() {
        credits = 0
        isSubscribed = false
        userId = nil

        try? keychain.delete(forKey: creditsKey)
        try? keychain.delete(forKey: subscriptionKey)
        try? keychain.delete(forKey: userIdKey)
    }

    // MARK: - Private Helpers

    private func loadFromKeychain() {
        credits = (try? keychain.load(forKey: creditsKey)) ?? 5000 // Default credits
        isSubscribed = (try? keychain.load(forKey: subscriptionKey)) ?? false
        userId = try? keychain.load(forKey: userIdKey)
    }

    private func saveToKeychain<T: Codable>(_ value: T, forKey key: String) {
        do {
            try keychain.save(value, forKey: key)
        } catch {
            ErrorLogger.shared.log(error, context: "SecureStorage")
        }
    }
}

// MARK: - Migration Helper

/// Migrates data from UserDefaults to Keychain (run once)
enum SecureStorageMigration {
    static func migrateFromUserDefaults() {
        let defaults = UserDefaults.standard
        let secureData = SecureUserData.shared

        // Migrate credits
        if defaults.object(forKey: "userCredits") != nil {
            let credits = defaults.integer(forKey: "userCredits")
            if credits > 0 {
                secureData.setCredits(credits)
                defaults.removeObject(forKey: "userCredits")
                ErrorLogger.shared.logInfo("Migrated credits to Keychain", context: "Migration")
            }
        }

        // Migrate subscription status
        if defaults.object(forKey: "isSubscribed") != nil {
            let isSubscribed = defaults.bool(forKey: "isSubscribed")
            secureData.setSubscribed(isSubscribed)
            defaults.removeObject(forKey: "isSubscribed")
            ErrorLogger.shared.logInfo("Migrated subscription status to Keychain", context: "Migration")
        }
    }
}
