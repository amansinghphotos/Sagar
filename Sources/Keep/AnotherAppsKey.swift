import CryptoKit
import Foundation
import LocalAuthentication
import Security

/// A key another app kept in the login keychain, its bytes as they are, found by the name it gave the key.
/// Another app made it, so reading it makes macOS ask for the Mac's password, once.
nonisolated package enum AnotherAppsKey {
    /// Whether this Mac has the key. It is looked for without being read, so nothing comes up on screen.
    package static func isHere(named account: String) -> Bool {
        let silent = LAContext()
        silent.interactionNotAllowed = true
        let status = SecItemCopyMatching(
            query(account).merging([kSecUseAuthenticationContext: silent]) { $1 } as CFDictionary, nil)
        return status == errSecSuccess || status == errSecInteractionNotAllowed
    }

    /// The key, read. macOS asks first; Always Allow means it never asks again.
    package static func read(named account: String) throws -> SymmetricKey {
        var found: CFTypeRef?
        let status = SecItemCopyMatching(query(account).merging([kSecReturnData: true]) { $1 } as CFDictionary, &found)
        guard status == errSecSuccess, let data = found as? Data else { throw SealError.keychain(status) }
        return SymmetricKey(data: data)
    }

    private static func query(_ account: String) -> [CFString: Any] {
        [kSecClass: kSecClassGenericPassword, kSecAttrAccount: account]
    }
}
