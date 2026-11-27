import CryptoKit
import Foundation
import Keep
import LocalAuthentication
import Security

/// The key the earlier Chete kept its history under: a password in the login keychain, its 32 bytes as they are.
/// Another app made it, so reading it makes macOS ask for the Mac's password, once.
nonisolated enum EarlierKey {
    static let service = "Theatre.Chete"
    static let account = "History Key"

    /// Whether this Mac has the key. It is looked for without being read, so nothing comes up on screen.
    static func isHere(service: String = service) -> Bool {
        let silent = LAContext()
        silent.interactionNotAllowed = true
        let status = SecItemCopyMatching(
            query(service).merging([kSecUseAuthenticationContext: silent]) { $1 } as CFDictionary, nil)
        return status == errSecSuccess || status == errSecInteractionNotAllowed
    }

    /// The key, read. macOS asks first; Always Allow means it never asks again.
    static func read(service: String = service) throws -> SymmetricKey {
        var found: CFTypeRef?
        let status = SecItemCopyMatching(query(service).merging([kSecReturnData: true]) { $1 } as CFDictionary, &found)
        guard status == errSecSuccess, let data = found as? Data else { throw SealError.keychain(status) }
        return SymmetricKey(data: data)
    }

    private static func query(_ service: String) -> [CFString: Any] {
        [kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: account]
    }
}
