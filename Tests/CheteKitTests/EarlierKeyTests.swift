import CryptoKit
import Foundation
import Security
import Testing

@testable import CheteKit

/// A key kept as the earlier Chete kept its own, under a made-up name the real one never uses, and removed after.
private struct MadeUpKey {
    let service = "Sagar Tests · \(UUID().uuidString)"
    let bytes = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }

    func kept() {
        let item: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: EarlierKey.account,
            kSecValueData: bytes,
        ]
        SecItemAdd(item as CFDictionary, nil)
    }

    func removed() {
        let item: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: service]
        SecItemDelete(item as CFDictionary)
    }
}

@Test func theEarlierKeyIsFoundWithoutBeingReadAndThenRead() throws {
    let key = MadeUpKey()
    defer { key.removed() }
    #expect(!EarlierKey.isHere(service: key.service))
    key.kept()
    #expect(EarlierKey.isHere(service: key.service))
    #expect(try EarlierKey.read(service: key.service).withUnsafeBytes { Data($0) } == key.bytes)
}

@Test func theEarlierCheteIsLookedForUnderItsOwnName() {
    #expect(EarlierKey.service == "Theatre.Chete" && EarlierKey.account == "History Key")
}
