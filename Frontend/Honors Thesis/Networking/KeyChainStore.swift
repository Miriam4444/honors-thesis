//
//  KeyChainStore.swift
//  Honors Thesis
//
//  Created by Miriam Abecasis on 11/3/26.
//saves the login token in the Keychain (the device's encrypted password storage),
//so you stay logged in when you reopen the app. tokens are secrets, so they shouldn't
//go in UserDefaults, which isn't encrypted.

import Foundation
import Security

enum KeychainStore {
    private static let service = "HonorsThesis"
    private static let account = "sessionToken"

    private static var baseQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    static func saveToken(_ token: String) {
        deleteToken() //only ever keep one
        var query = baseQuery
        query[kSecValueData as String] = Data(token.utf8)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("KeychainStore: couldn't save the token (\(status))")
        }
    }

    static func loadToken() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func deleteToken() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}
