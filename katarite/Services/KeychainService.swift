//
//  KeychainService.swift
//  katarite
//
//  Created by Felipe Basurto on 2025-06-06.
//

import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
    
    private let service = "com.katarite.apikeys"
    
    // MARK: - API Key Storage
    func storeAPIKey(_ key: String, for provider: String) -> Bool {
        let data = key.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func retrieveAPIKey(for provider: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    func deleteAPIKey(for provider: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    func deleteAllAPIKeys() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

// MARK: - Convenience Methods
extension KeychainService {
    func storeDeepSeekKey(_ key: String) -> Bool {
        return storeAPIKey(key, for: "deepseek")
    }
    
    func retrieveDeepSeekKey() -> String? {
        return retrieveAPIKey(for: "deepseek")
    }
    
    func storeGeminiKey(_ key: String) -> Bool {
        return storeAPIKey(key, for: "gemini")
    }
    
    func retrieveGeminiKey() -> String? {
        return retrieveAPIKey(for: "gemini")
    }
    
    func storeOpenAIKey(_ key: String) -> Bool {
        return storeAPIKey(key, for: "openai")
    }
    
    func retrieveOpenAIKey() -> String? {
        return retrieveAPIKey(for: "openai")
    }
} 