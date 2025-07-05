//
//  AuthService.swift
//  LabTest
//
//  Created by $HahMa on 03/07/25.
//

import Supabase
import Foundation

final class AuthService: AuthProtocol {
    private let client = SupabaseManager.shared.client
    
    func signUp(email: String, password: String, name: String) async throws -> User {
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: ["name": AnyJSON.string(name)]
        )
        
        let user = response.user
        
        // Insert user into public.users table using the new from() method
        let newUser = User(
            id: user.id,
            email: user.email ?? email,
            name: name,
            createdAt: Date()
        )
        
        try await client
            .from("users")
            .insert(newUser)
            .execute()
        
        // Save credentials to keychain for multi-user support
        do {
            let session = try await client.auth.session
            await saveCredentialsForUser(newUser, accessToken: session.accessToken, refreshToken: session.refreshToken)
        } catch {
            print("Could not get session for credential saving: \(error)")
        }
        
        return newUser
    }
    
    func signIn(email: String, password: String) async throws -> User {
        do {
                // 1. Attempt to sign in
                let response = try await client.auth.signIn(email: email, password: password)
                
                // 2. Verify we got a user
                let user = response.user
                
                // 3. Debug print the user ID
                print("Signed in user ID:", user.id)
                
                // 4. Fetch user profile from 'users' table
                let query = try await client
                    .from("users")
                    .select()
                    .eq("id", value: user.id)
                    .single()
                    .execute()
                
                // 5. Debug print the raw data
                print("Raw user data:", String(data: query.data, encoding: .utf8) ?? "No data")
                
                // 6. Configure decoder
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                decoder.dateDecodingStrategy = .iso8601 // Add if you're using dates
                
                // 7. Decode and return
                let profile = try decoder.decode(User.self, from: query.data)
                print("Successfully decoded user profile:", profile)
                
                // 8. Save credentials to keychain for multi-user support
                do {
                    let session = try await client.auth.session
                    await saveCredentialsForUser(profile, accessToken: session.accessToken, refreshToken: session.refreshToken)
                } catch {
                    print("Could not get session for credential saving: \(error)")
                }
                
                return profile
                
            } catch {
                print("Sign in error:", error)
                throw error // Re-throw the error for the caller to handle
            }
    }
    
//    func signIn(email: String, password: String) async throws -> User {
//        let response = try await client.auth.signIn(email: email, password: password)
//        let user = response.user
//
//        // Fetch user profile using the new from() method
//        let query = try await client
//            .from("users")
//            .select()
//            .eq("id", value: user.id)
//            .single()
//            .execute()
//
//        guard !query.data.isEmpty else {
//            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User profile not found in database."])
//        }
//        
//        let decoder = JSONDecoder()
//        decoder.keyDecodingStrategy = .convertFromSnakeCase
//        return try decoder.decode(User.self, from: query.data)
//    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func getCurrentUser() async throws -> User? {
        do {
            let session = try await client.auth.session
            
            // Fetch user profile using the new from() method
            let query = try await client
                .from("users")
                .select()
                .eq("id", value: session.user.id)
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(User.self, from: query.data)
        } catch {
            return nil
        }
    }
    
    // MARK: - Private Methods
    private func saveCredentialsForUser(_ user: User, accessToken: String, refreshToken: String) async {
        let credentials = UserCredentials(
            userId: user.id.uuidString,
            email: user.email,
            name: user.name ?? user.email,
            accessToken: accessToken,
            refreshToken: refreshToken
        )
        
        do {
            let keychainManager = KeychainManager()
            try keychainManager.saveCredentials(credentials)
            print("Successfully saved credentials for user: \(user.name ?? user.email)")
        } catch {
            print("Failed to save credentials: \(error)")
        }
    }
}
