//
//  Constants.swift
//  LabTest
//
//  Created by $HahMa on 03/07/25.
//

import Foundation

// MARK: - Constants
enum Constants {
    // This file is kept for backward compatibility
    // New code should use AppConfiguration instead
    
    @available(*, deprecated, message: "Use AppConfiguration.Supabase.url instead")
    static let supabaseURL = AppConfiguration.Supabase.url
    
    @available(*, deprecated, message: "Use AppConfiguration.Supabase.key instead")
    static let supabaseKey = AppConfiguration.Supabase.key
}

