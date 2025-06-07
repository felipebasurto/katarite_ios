import Foundation
import CryptoKit

/// Secure API Key Manager for embedded developer-provided API keys
/// Uses AES.GCM encryption with HKDF key derivation for obfuscation
class APIKeyManager {
    
    // MARK: - Singleton
    static let shared = APIKeyManager()
    private init() {}
    
    // MARK: - Obfuscated Secrets
    // These are generated using the encryption methods below
    // In production, replace these with your actual encrypted API keys
    
    // Obfuscated password and shared secret (generated via uuidgen)
    private let obfuscatedPassword: [UInt8] = [0xCE, 0xCD, 0xB9, 0xB9, 0xC7, 0xBC, 0xCA, 0xBA, 0xD2, 0xBB, 0xBA, 0xCA, 0xBC, 0xD2, 0xCB, 0xC6, 0xBE, 0xBD, 0xD2, 0xC6, 0xBC, 0xBE, 0xBE, 0xD2, 0xCB, 0xCE, 0xCB, 0xCA, 0xC9, 0xB9, 0xCF, 0xCD, 0xC9, 0xC7, 0xBD, 0xC8]
    
    private let obfuscatedSharedSecret: [UInt8] = [0xCA, 0xCD, 0xC7, 0xBD, 0xC9, 0xCE, 0xCB, 0xC7, 0xD2, 0xBA, 0xCD, 0xBB, 0xCE, 0xD2, 0xCB, 0xB9, 0xCE, 0xC8, 0xD2, 0xBE, 0xCC, 0xBA, 0xC6, 0xD2, 0xBC, 0xCE, 0xBA, 0xC7, 0xC8, 0xBA, 0xCF, 0xC7, 0xCF, 0xC8, 0xCF, 0xBB]
    
    // Encrypted API Keys (actual encrypted keys)
    private let encryptedDeepSeekKey: [UInt8] = [0x5D, 0x43, 0xA6, 0x04, 0x20, 0xCF, 0xB8, 0x38, 0xC7, 0xAF, 0x86, 0xF9, 0xB4, 0xFB, 0xDD, 0x53, 0xF8, 0xEC, 0x48, 0x1B, 0xCE, 0x40, 0x6F, 0xFE, 0x12, 0xEE, 0x7C, 0x51, 0xBB, 0x7C, 0x76, 0x82, 0x5E, 0x3B, 0x86, 0x14, 0xFC, 0x5F, 0xD1, 0x44, 0xD7, 0xF2, 0x81, 0xD3, 0xA6, 0xE5, 0x9B, 0x5F, 0x89, 0x4B, 0xD3, 0xC4, 0x21, 0x27, 0x58, 0xC9, 0x2E, 0x82, 0xE3, 0xC0, 0xFD, 0xE4, 0x85]
    
    private let encryptedGeminiKey: [UInt8] = [0xE7, 0x1D, 0x7E, 0x42, 0xBD, 0x74, 0x5F, 0x8E, 0xC1, 0x9E, 0x80, 0x7B, 0x4F, 0x20, 0x14, 0x61, 0x16, 0xC7, 0x4D, 0x0A, 0xED, 0xBB, 0x00, 0x90, 0x2C, 0x66, 0x4C, 0x96, 0x6C, 0x06, 0x6E, 0xF5, 0x11, 0x5F, 0xAD, 0x61, 0x06, 0x28, 0x79, 0xA7, 0x93, 0x14, 0x87, 0x3C, 0x2D, 0x3A, 0xB5, 0xF9, 0x55, 0xC2, 0x7A, 0x97, 0x71, 0x5F, 0x5D, 0xEC, 0xA7, 0x56, 0x5F, 0x81, 0xE4, 0xBA, 0xF1, 0x15, 0x17, 0xB7, 0x83]
    
    private let encryptedOpenAIKey: [UInt8] = [
        // OpenAI key not provided in .env.local - add if needed
    ]
    
    // MARK: - Key Derivation
    
    /// Derives the AES key using HKDF from obfuscated password and shared secret
    private func deriveAESKey() throws -> SymmetricKey {
        // Simple XOR deobfuscation (in production, use a more sophisticated method)
        let password = String(bytes: obfuscatedPassword.map { $0 ^ 0xFF }, encoding: .utf8) ?? ""
        let sharedSecret = String(bytes: obfuscatedSharedSecret.map { $0 ^ 0xFF }, encoding: .utf8) ?? ""
        
        guard let passwordData = password.data(using: .utf8),
              let sharedSecretData = sharedSecret.data(using: .utf8) else {
            throw APIKeyError.keyDerivationFailed
        }
        
        // Use HKDF to derive a 256-bit AES key
        let derivedKey = HKDF<SHA512>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: passwordData),
            info: sharedSecretData,
            outputByteCount: 32 // 256 bits for AES-256
        )
        
        return derivedKey
    }
    
    // MARK: - API Key Retrieval
    
    /// Retrieves the DeepSeek API key
    func getDeepSeekAPIKey() throws -> String {
        return try decryptAPIKey(encryptedData: encryptedDeepSeekKey)
    }
    
    /// Retrieves the Gemini API key
    func getGeminiAPIKey() throws -> String {
        return try decryptAPIKey(encryptedData: encryptedGeminiKey)
    }
    
    /// Retrieves the OpenAI API key (if needed)
    func getOpenAIAPIKey() throws -> String {
        return try decryptAPIKey(encryptedData: encryptedOpenAIKey)
    }
    
    // MARK: - Decryption
    
    /// Decrypts an API key using AES.GCM
    private func decryptAPIKey(encryptedData: [UInt8]) throws -> String {
        guard !encryptedData.isEmpty else {
            throw APIKeyError.invalidEncryptedData
        }
        
        let aesKey = try deriveAESKey()
        let encryptedDataObj = Data(encryptedData)
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedDataObj)
            let decryptedData = try AES.GCM.open(sealedBox, using: aesKey)
            
            guard let apiKey = String(data: decryptedData, encoding: .utf8) else {
                throw APIKeyError.decryptionFailed
            }
            
            return apiKey
        } catch {
            throw APIKeyError.decryptionFailed
        }
    }
    
    // MARK: - Helper Methods for Key Generation (Development Only)
    
    #if DEBUG
    /// Helper method to encrypt API keys during development
    /// Use this to generate the encrypted byte arrays for your actual API keys
    func encryptAPIKey(_ plainTextKey: String, password: String, sharedSecret: String) throws -> [UInt8] {
        guard let passwordData = password.data(using: .utf8),
              let sharedSecretData = sharedSecret.data(using: .utf8),
              let keyData = plainTextKey.data(using: .utf8) else {
            throw APIKeyError.encryptionFailed
        }
        
        let aesKey = HKDF<SHA512>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: passwordData),
            info: sharedSecretData,
            outputByteCount: 32
        )
        
        let sealedBox = try AES.GCM.seal(keyData, using: aesKey)
        guard let combinedData = sealedBox.combined else {
            throw APIKeyError.encryptionFailed
        }
        
        return Array(combinedData)
    }
    
    /// Helper method to obfuscate strings (simple XOR)
    func obfuscateString(_ input: String) -> [UInt8] {
        return input.utf8.map { $0 ^ 0xFF }
    }
    #endif
}

// MARK: - Error Types

enum APIKeyError: Error, LocalizedError {
    case keyDerivationFailed
    case invalidEncryptedData
    case decryptionFailed
    case encryptionFailed
    
    var errorDescription: String? {
        switch self {
        case .keyDerivationFailed:
            return "Failed to derive encryption key"
        case .invalidEncryptedData:
            return "Invalid encrypted data format"
        case .decryptionFailed:
            return "Failed to decrypt API key"
        case .encryptionFailed:
            return "Failed to encrypt API key"
        }
    }
}

// MARK: - Usage Example and Setup Instructions

/*
 SETUP INSTRUCTIONS:
 
 1. Generate your password and shared secret:
    - Run `uuidgen` in terminal twice to get two UUIDs
    - Use these as your password and shared secret
 
 2. Encrypt your API keys (in DEBUG mode):
    ```swift
    let manager = APIKeyManager.shared
    let password = "YOUR-UUID-PASSWORD"
    let sharedSecret = "YOUR-UUID-SHARED-SECRET"
    
    // Encrypt your actual API keys
    let encryptedDeepSeek = try manager.encryptAPIKey("your-deepseek-key", password: password, sharedSecret: sharedSecret)
    let encryptedGemini = try manager.encryptAPIKey("your-gemini-key", password: password, sharedSecret: sharedSecret)
    
    // Obfuscate your password and shared secret
    let obfuscatedPassword = manager.obfuscateString(password)
    let obfuscatedSharedSecret = manager.obfuscateString(sharedSecret)
    
    // Print the byte arrays to copy into your code
    print("Obfuscated Password: \(obfuscatedPassword)")
    print("Obfuscated Shared Secret: \(obfuscatedSharedSecret)")
    print("Encrypted DeepSeek Key: \(encryptedDeepSeek)")
    print("Encrypted Gemini Key: \(encryptedGemini)")
    ```
 
 3. Replace the placeholder byte arrays above with your actual encrypted data
 
 4. Remove the DEBUG helper methods before production release
 
 USAGE:
 ```swift
 do {
     let deepSeekKey = try APIKeyManager.shared.getDeepSeekAPIKey()
     let geminiKey = try APIKeyManager.shared.getGeminiAPIKey()
     // Use the keys for API calls
 } catch {
     print("Failed to retrieve API key: \(error)")
 }
 ```
 
 SECURITY NOTES:
 - This approach makes static analysis more difficult but not impossible
 - For maximum security, consider additional obfuscation techniques
 - Regularly rotate your API keys and update the encrypted values
 - Monitor API usage for any suspicious activity
 - Consider implementing certificate pinning for API calls
 */ 