import CryptoKit
import Foundation
import Security
import Testing

@testable import Keep

/// A key kept as another app keeps its own, under a made-up account name the real one never uses, and removed after.
private struct MadeUpKey {
    let account = "Sagar Tests · \(UUID().uuidString)"
    let bytes = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }

    func kept() {
        let item: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword, kSecAttrService: "Sagar Tests", kSecAttrAccount: account,
            kSecValueData: bytes,
        ]
        SecItemAdd(item as CFDictionary, nil)
    }

    func removed() {
        let item: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrAccount: account]
        SecItemDelete(item as CFDictionary)
    }
}

@Test func anotherAppsKeyIsFoundWithoutBeingReadAndThenRead() throws {
    let key = MadeUpKey()
    defer { key.removed() }
    #expect(!AnotherAppsKey.isHere(named: key.account))
    key.kept()
    #expect(AnotherAppsKey.isHere(named: key.account))
    #expect(try AnotherAppsKey.read(named: key.account).withUnsafeBytes { Data($0) } == key.bytes)
}
