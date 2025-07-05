//
//  AppConfiguration.swift
//  LabTest
//
//  Created by $HahMa on 04/07/25.
//

import Foundation

// MARK: - App Configuration
struct AppConfiguration {
    
    // MARK: - Supabase Configuration
    struct Supabase {
        static let url = "https://tgmwlrfvfgxfpgntwaep.supabase.co"
        static let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRnbXdscmZ2Zmd4ZnBnbnR3YWVwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE1NTMyOTMsImV4cCI6MjA2NzEyOTI5M30.qmqZRZMRnVxGPj7riNWNkr9s0fjWg5esFQB8FcUqPQ8"
    }
    
    // MARK: - Validation Rules
    struct Validation {
        static let minimumPasswordLength = 6
        static let minimumNameLength = 2
        static let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    }
    
    // MARK: - UI Configuration
    struct UI {
        static let cornerRadius: CGFloat = 8
        static let animationDuration: TimeInterval = 0.3
        static let profileImageSize: CGFloat = 100
        static let profileImageCornerRadius: CGFloat = 50
    }
    
    // MARK: - Storyboard Identifiers
    struct StoryboardIdentifiers {
        static let loginViewController = "LoginViewController"
        static let signupViewController = "SignupViewController"
        static let tabBarController = "tabbarVC"
    }
} 