//
//  KeychainManager.swift
//  LabTest
//
//  Created by $HahMa on 04/07/25.
//

import Foundation
import Security

// MARK: - Keychain Errors
enum KeychainError: LocalizedError {
    case duplicateItem
    case unknown(OSStatus)
    case itemNotFound
    case invalidItemFormat
    case encodingError
    
    var errorDescription: String? {
        switch self {
        case .duplicateItem:
            return "User already exists"
        case .unknown(let status):
            return "Keychain error: \(status)"
        case .itemNotFound:
            return "User not found"
        case .invalidItemFormat:
            return "Invalid data format"
        case .encodingError:
            return "Failed to encode/decode data"
        }
    }
}

// MARK: - User Credentials
struct UserCredentials: Codable {
    let userId: String
    let email: String
    let name: String
    let accessToken: String
    let refreshToken: String
    let createdAt: Date
    
    init(userId: String, email: String, name: String, accessToken: String, refreshToken: String) {
        self.userId = userId
        self.email = email
        self.name = name
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.createdAt = Date()
    }
}

// MARK: - Keychain Manager Protocol
protocol KeychainManagerProtocol {
    func saveCredentials(_ credentials: UserCredentials) throws
    func getCredentials(for userId: String) throws -> UserCredentials
    func updateCredentials(_ credentials: UserCredentials) throws
    func deleteCredentials(for userId: String) throws
    func getAllUserIds() -> [String]
    func clearAllCredentials() throws
}

// MARK: - Keychain Manager
final class KeychainManager: KeychainManagerProtocol {
    
    // MARK: - Properties
    private let service = "com.labtest.app"
    private let userDefaultsKey = "stored_user_ids"
    
    // MARK: - Public Methods
    func saveCredentials(_ credentials: UserCredentials) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: credentials.userId,
            kSecValueData as String: try encodeCredentials(credentials),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            // Save user ID to UserDefaults for tracking
            saveUserIdToDefaults(credentials.userId)
        case errSecDuplicateItem:
            throw KeychainError.duplicateItem
        default:
            throw KeychainError.unknown(status)
        }
    }
    
    func getCredentials(for userId: String) throws -> UserCredentials {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: userId,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainError.invalidItemFormat
            }
            return try decodeCredentials(from: data)
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        default:
            throw KeychainError.unknown(status)
        }
    }
    
    func updateCredentials(_ credentials: UserCredentials) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: credentials.userId
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: try encodeCredentials(credentials)
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        switch status {
        case errSecSuccess:
            break
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        default:
            throw KeychainError.unknown(status)
        }
    }
    
    func deleteCredentials(for userId: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: userId
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess:
            // Remove user ID from UserDefaults
            removeUserIdFromDefaults(userId)
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        default:
            throw KeychainError.unknown(status)
        }
    }
    
    func getAllUserIds() -> [String] {
        return UserDefaults.standard.stringArray(forKey: userDefaultsKey) ?? []
    }
    
    func clearAllCredentials() throws {
        let userIds = getAllUserIds()
        
        for userId in userIds {
            try? deleteCredentials(for: userId)
        }
        
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    // MARK: - Private Methods
    private func encodeCredentials(_ credentials: UserCredentials) throws -> Data {
        do {
            return try JSONEncoder().encode(credentials)
        } catch {
            throw KeychainError.encodingError
        }
    }
    
    private func decodeCredentials(from data: Data) throws -> UserCredentials {
        do {
            return try JSONDecoder().decode(UserCredentials.self, from: data)
        } catch {
            throw KeychainError.encodingError
        }
    }
    
    private func saveUserIdToDefaults(_ userId: String) {
        var userIds = getAllUserIds()
        if !userIds.contains(userId) {
            userIds.append(userId)
            UserDefaults.standard.set(userIds, forKey: userDefaultsKey)
        }
    }
    
    private func removeUserIdFromDefaults(_ userId: String) {
        var userIds = getAllUserIds()
        userIds.removeAll { $0 == userId }
        UserDefaults.standard.set(userIds, forKey: userDefaultsKey)
    }
} 