//
//  ValidationService.swift
//  LabTest
//
//  Created by $HahMa on 04/07/25.
//

import Foundation

// MARK: - Validation Errors
enum ValidationError: LocalizedError {
    case emptyField(String)
    case invalidEmail
    case weakPassword
    case invalidName
    
    var errorDescription: String? {
        switch self {
        case .emptyField(let fieldName):
            return "\(fieldName) cannot be empty"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 6 characters long"
        case .invalidName:
            return "Please enter a valid name"
        }
    }
}

// MARK: - Validation Protocol
protocol ValidationProtocol {
    func validateEmail(_ email: String) throws
    func validatePassword(_ password: String) throws
    func validateName(_ name: String) throws
    func validateNonEmpty(_ value: String, fieldName: String) throws
}

// MARK: - Validation Service
final class ValidationService: ValidationProtocol {
    
    private let emailRegex = AppConfiguration.Validation.emailRegex
    private let minimumPasswordLength = AppConfiguration.Validation.minimumPasswordLength
    
    func validateEmail(_ email: String) throws {
        try validateNonEmpty(email, fieldName: "Email")
        
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            throw ValidationError.invalidEmail
        }
    }
    
    func validatePassword(_ password: String) throws {
        try validateNonEmpty(password, fieldName: "Password")
        
        guard password.count >= minimumPasswordLength else {
            throw ValidationError.weakPassword
        }
    }
    
    func validateName(_ name: String) throws {
        try validateNonEmpty(name, fieldName: "Name")
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.count >= AppConfiguration.Validation.minimumNameLength else {
            throw ValidationError.invalidName
        }
    }
    
    func validateNonEmpty(_ value: String, fieldName: String) throws {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty else {
            throw ValidationError.emptyField(fieldName)
        }
    }
} 