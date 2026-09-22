//
//  PINStore.swift
//  Jinsula
//
//  Keychain-backed store for the family setup PIN. The PIN lives in the
//  Keychain — never in the plaintext settings JSON (SPEC.md "Setup screen" §5).
//  `hasPIN` derives from Keychain presence, so the gate needs no separate flag.
//
//  There is deliberately no recovery flow: a forgotten PIN can only be cleared
//  by reinstalling the app (which wipes the local JSON anyway). See SPEC.md §5.
//

import Foundation
import Security

protocol PINStoring {
    /// Whether a PIN is currently set (derived from Keychain presence).
    var hasPIN: Bool { get }
    /// Stores (or replaces) the setup PIN.
    func setPIN(_ pin: String)
    /// True only when `pin` matches the stored PIN.
    func verify(_ pin: String) -> Bool
    /// Removes the stored PIN.
    func clear()
}

/// Keychain-backed store. A 4-digit PIN is a low-value secret, but the Keychain
/// (protected `WhenUnlockedThisDeviceOnly`) is still the right home for it — it
/// keeps the PIN out of the readable settings file and out of backups.
final class PINStore: PINStoring {
    private let service: String
    private let account = "setupPIN"

    init(service: String = "uk.co.zlurgg.Jinsula.pin") {
        self.service = service
    }

    var hasPIN: Bool { readPIN() != nil }

    func setPIN(_ pin: String) {
        // Replace any existing item so a change-PIN always overwrites cleanly.
        SecItemDelete(baseQuery() as CFDictionary)

        var attributes = baseQuery()
        attributes[kSecValueData as String] = Data(pin.utf8)
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        SecItemAdd(attributes as CFDictionary, nil)
    }

    func verify(_ pin: String) -> Bool {
        guard let stored = readPIN() else { return false }
        return stored == pin
    }

    func clear() {
        SecItemDelete(baseQuery() as CFDictionary)
    }

    // MARK: - Keychain plumbing

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private func readPIN() -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
