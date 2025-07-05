//
//  UserManager.swift
//  LabTest
//
//  Created by $HahMa on 04/07/25.
//

import Foundation
import Combine

// MARK: - User Manager Errors
enum UserManagerError: LocalizedError {
    case noActiveUser
    case userNotFound
    case switchFailed(String)
    case saveFailed(String)
    case removeFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noActiveUser:
            return "No active user found"
        case .userNotFound:
            return "User not found"
        case .switchFailed(let message):
            return "Failed to switch user: \(message)"
        case .saveFailed(let message):
            return "Failed to save user: \(message)"
        case .removeFailed(let message):
            return "Failed to remove user: \(message)"
        }
    }
}

// MARK: - User Manager Protocol
protocol UserManagerProtocol: ObservableObject {
    var currentUser: User? { get }
    var allUsers: [User] { get }
    var isLoading: Bool { get }
    
    func switchToUser(_ userId: String) async throws
    func addUser(_ user: User) async throws
    func removeUser(_ userId: String) async throws
    func getCurrentUserCredentials() throws -> UserCredentials
    func saveUserCredentials(_ credentials: UserCredentials) throws
    func loadAllUsers() async
}

// MARK: - User Manager
final class UserManager: UserManagerProtocol {
    
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var allUsers: [User] = []
    @Published var isLoading = false
    
    // MARK: - Dependencies
    private let keychainManager: KeychainManagerProtocol
    private let authService: AuthProtocol
    
    // MARK: - Initialization
    init(keychainManager: KeychainManagerProtocol = KeychainManager(),
         authService: AuthProtocol = AuthService()) {
        self.keychainManager = keychainManager
        self.authService = authService
    }
    
    // MARK: - Public Methods
    @MainActor func switchToUser(_ userId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        print("Attempting to switch to user: \(userId)")
        print("Available users: \(allUsers.map { "\($0.name ?? $0.email) (\($0.id.uuidString))" })")
        
        do {
            // Find the user in our list
            guard let targetUser = allUsers.first(where: { $0.id.uuidString == userId }) else {
                throw UserManagerError.userNotFound
            }
            
            print("Found target user: \(targetUser.name ?? targetUser.email)")
            
            // Try to get credentials for the target user
            do {
                let credentials = try keychainManager.getCredentials(for: userId)
                print("Found credentials for user: \(credentials.name)")
            } catch {
                print("No credentials found for user \(userId), but continuing with switch")
            }
            
            // Update current user
            currentUser = targetUser
            
            // Persist the current user ID
            UserDefaults.standard.set(userId, forKey: "current_user_id")
            
            print("Successfully switched to user: \(targetUser.name ?? targetUser.email)")
            
        } catch {
            print("Error switching user: \(error)")
            throw UserManagerError.switchFailed(error.localizedDescription)
        }
    }
    
    @MainActor func addUser(_ user: User) async throws {
        isLoading = true
        defer { isLoading = false }
        
        print("Adding user: \(user.name ?? user.email) with ID: \(user.id.uuidString)")
        
        // Check if user already exists
        if allUsers.contains(where: { $0.id == user.id }) {
            print("User already exists, setting as current user")
            // Set as current user even if already exists
            currentUser = user
            UserDefaults.standard.set(user.id.uuidString, forKey: "current_user_id")
            return
        }
        
        // Add to all users list
        allUsers.append(user)
        
        // Set as current user
        currentUser = user
        UserDefaults.standard.set(user.id.uuidString, forKey: "current_user_id")
        
        // Save user list to UserDefaults
        try saveUserList()
        
        print("Successfully added user: \(user.name ?? user.email) and set as current user")
    }
    
    @MainActor func removeUser(_ userId: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Remove from keychain
            try keychainManager.deleteCredentials(for: userId)
            
            // Remove from all users list
            allUsers.removeAll { $0.id.uuidString == userId }
            
            // If we removed the current user, set first user as active
            if currentUser?.id.uuidString == userId {
                if let firstUser = allUsers.first {
                    currentUser = firstUser
                    UserDefaults.standard.set(firstUser.id.uuidString, forKey: "current_user_id")
                } else {
                    currentUser = nil
                    UserDefaults.standard.removeObject(forKey: "current_user_id")
                }
            }
            
            // Save updated user list
            try saveUserList()
            
            print("Successfully removed user: \(userId)")
            
        } catch {
            throw UserManagerError.removeFailed(error.localizedDescription)
        }
    }
    
    func getCurrentUserCredentials() throws -> UserCredentials {
        guard let currentUser = currentUser else {
            throw UserManagerError.noActiveUser
        }
        
        return try keychainManager.getCredentials(for: currentUser.id.uuidString)
    }
    
    func saveUserCredentials(_ credentials: UserCredentials) throws {
        try keychainManager.saveCredentials(credentials)
    }
    
    @MainActor func loadAllUsers() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try to load from UserDefaults first
            if let data = UserDefaults.standard.data(forKey: "user_list"),
               let users = try? JSONDecoder().decode([User].self, from: data) {
                allUsers = users
                print("Loaded \(users.count) users from UserDefaults")
            } else {
                // Fallback to keychain if no UserDefaults data
                let userIds = keychainManager.getAllUserIds()
                print("Found user IDs in keychain: \(userIds)")
                var users: [User] = []
                
                for userId in userIds {
                    if let credentials = try? keychainManager.getCredentials(for: userId) {
                        let user = User(
                            id: UUID(uuidString: credentials.userId) ?? UUID(),
                            email: credentials.email,
                            name: credentials.name,
                            createdAt: credentials.createdAt
                        )
                        users.append(user)
                        print("Added user: \(user.name ?? user.email) with ID: \(user.id.uuidString)")
                    }
                }
                
                allUsers = users
                print("Loaded \(users.count) users from keychain")
            }
            
            // Load current user from persisted state
            let currentUserId = UserDefaults.standard.string(forKey: "current_user_id")
            print("Persisted current user ID: \(currentUserId ?? "none")")
            
            if let currentUserId = currentUserId,
               let persistedUser = allUsers.first(where: { $0.id.uuidString == currentUserId }) {
                // Restore the persisted current user
                currentUser = persistedUser
                print("Restored current user: \(persistedUser.name ?? persistedUser.email)")
            } else if !allUsers.isEmpty {
                // Set first user as active if no current user is persisted
                currentUser = allUsers.first
                UserDefaults.standard.set(allUsers.first?.id.uuidString, forKey: "current_user_id")
                print("Set current user to: \(allUsers.first?.name ?? allUsers.first?.email ?? "unknown")")
            } else {
                print("No users found")
            }
            
        } catch {
            print("Error loading users: \(error)")
        }
    }
    
    // MARK: - Private Methods
    private func saveUserList() throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(allUsers)
        UserDefaults.standard.set(data, forKey: "user_list")
    }
} 