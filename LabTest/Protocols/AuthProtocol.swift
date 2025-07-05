//
//  AuthProtocol.swift
//  LabTest
//
//  Created by $HahMa on 04/07/25.
//

import Foundation

// MARK: - Authentication Errors
enum AuthError: LocalizedError {
    case invalidCredentials
    case networkError(String)
    case userNotFound
    case signUpFailed(String)
    case signInFailed(String)
    case signOutFailed(String)
    case invalidEmail
    case weakPassword
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError(let message):
            return "Network error: \(message)"
        case .userNotFound:
            return "User not found"
        case .signUpFailed(let message):
            return "Sign up failed: \(message)"
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        case .signOutFailed(let message):
            return "Sign out failed: \(message)"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 6 characters long"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - Authentication Protocol
protocol AuthProtocol {
    func signUp(email: String, password: String, name: String) async throws -> User
    func signIn(email: String, password: String) async throws -> User
    func signOut() async throws
    func getCurrentUser() async throws -> User?
} 