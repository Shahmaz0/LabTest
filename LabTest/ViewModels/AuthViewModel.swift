//
//  AuthViewModel.swift
//  LabTest
//
//  Created by $HahMa on 04/07/25.
//

import Foundation
import Combine

// MARK: - Auth View Model Protocol
@MainActor
protocol AuthViewModelProtocol: ObservableObject {
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var isAuthenticated: Bool { get }
    
    func signIn(email: String, password: String)
    func signUp(email: String, password: String, name: String)
    func signOut()
    func clearError()
}

// MARK: - Auth View Model
@MainActor
final class AuthViewModel: AuthViewModelProtocol {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    
    // MARK: - Dependencies
    private let authService: AuthProtocol
    private let validationService: ValidationProtocol
    private let userManager: any UserManagerProtocol
    
    // MARK: - Initialization
    init(authService: AuthProtocol = AuthService(), 
         validationService: ValidationProtocol = ValidationService(),
         userManager: any UserManagerProtocol) {
        self.authService = authService
        self.validationService = validationService
        self.userManager = userManager
    }
    
    // MARK: - Public Methods
    func signIn(email: String, password: String) {
        Task {
            await performSignIn(email: email, password: password)
        }
    }
    
    func signUp(email: String, password: String, name: String) {
        Task {
            await performSignUp(email: email, password: password, name: name)
        }
    }
    
    func signOut() {
        Task {
            await performSignOut()
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    private func performSignIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Validate inputs
            try validationService.validateEmail(email)
            try validationService.validatePassword(password)
            
            // Perform sign in
            let user = try await authService.signIn(email: email, password: password)
            
            // Add user to user manager if not already present
            try await userManager.addUser(user)
            
            isAuthenticated = true
            print("Successfully signed in user: \(user.name ?? user.email)")
            
        } catch let error as ValidationError {
            errorMessage = error.localizedDescription
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func performSignUp(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Validate inputs
            try validationService.validateEmail(email)
            try validationService.validatePassword(password)
            try validationService.validateName(name)
            
            // Perform sign up
            let user = try await authService.signUp(email: email, password: password, name: name)
            
            // Add user to user manager
            try await userManager.addUser(user)
            
            isAuthenticated = true
            print("Successfully signed up user: \(user.name ?? user.email)")
            
        } catch let error as ValidationError {
            errorMessage = error.localizedDescription
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func performSignOut() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signOut()
            isAuthenticated = false
            print("Successfully signed out")
            
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
} 