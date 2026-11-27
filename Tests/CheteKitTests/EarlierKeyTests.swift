import CryptoKit
import Foundation
import Security
import Testing

@testable import CheteKit

/// A key kept as the earlier Chete kept its own, under a made-up account name the real one never uses, and removed after.
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

@Test func theEarlierKeyIsFoundWithoutBeingReadAndThenRead() throws {
    let key = MadeUpKey()
    defer { key.removed() }
    #expect(!EarlierKey.isHere(account: key.account))
    key.kept()
    #expect(EarlierKey.isHere(account: key.account))
    #expect(try EarlierKey.read(account: key.account).withUnsafeBytes { Data($0) } == key.bytes)
}
