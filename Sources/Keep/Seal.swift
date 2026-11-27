import CryptoKit
import Foundation
import LocalAuthentication
import Security

/// A key kept in the login keychain, which seals a person's things so that only this Mac opens them.
/// It never asks anything on screen: where macOS would ask, it fails instead.
package struct Seal: Sendable {
    private let key: SymmetricKey

    /// The key kept under a name, made and kept there the first time it is asked for.
    package init(named name: String) throws {
        if let found = try Self.find(named: name) {
            key = found
            return
        }
        let made = SymmetricKey(size: .bits256)
        var item = Self.query(named: name)
        item[kSecValueData] = made.withUnsafeBytes { Data($0) }
        item[kSecAttrLabel] = name
        switch SecItemAdd(item as CFDictionary, nil) {
        case errSecSuccess: key = made
        // Another part of the app made it first: theirs is the one kept.
        case errSecDuplicateItem: key = try Self.find(named: name) ?? made
        case let status: throw SealError.keychain(status)
        }
    }

    /// Removes the key kept under a name. What it sealed can never be opened again.
    package static func forget(named name: String) throws {
        let status = SecItemDelete(query(named: name) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw SealError.keychain(status) }
    }

    /// The data, sealed so that it cannot be read or changed unseen.
    package func seal(_ data: Data) throws -> Data {
        // A nonce of the standard size always gives the combined form.
        try AES.GCM.seal(data, using: key).combined ?? Data()
    }

    /// Sealed data, opened. Data that was changed, or sealed by another key, is an error.
    package func open(_ sealed: Data) throws -> Data {
        try AES.GCM.open(AES.GCM.SealedBox(combined: sealed), using: key)
    }

    private static func find(named name: String) throws -> SymmetricKey? {
        var item = query(named: name)
        item[kSecReturnData] = true
        var found: CFTypeRef?
        switch SecItemCopyMatching(item as CFDictionary, &found) {
        case errSecSuccess:
            guard let data = found as? Data else { throw SealError.keychain(errSecDecode) }
            return SymmetricKey(data: data)
        case errSecItemNotFound: return nil
        case let status: throw SealError.keychain(status)
        }
    }

    /// The one keychain item for a name: a password in the login keychain, never shown or asked for.
    private static func query(named name: String) -> [CFString: Any] {
        let silent = LAContext()
        silent.interactionNotAllowed = true
        return [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: name,
            kSecAttrAccount: "Key",
            kSecUseAuthenticationContext: silent,
        ]
    }
}

/// Why sealing failed: the keychain's own status, which `SecCopyErrorMessageString` explains.
package enum SealError: Error, Equatable {
    case keychain(OSStatus)
}
