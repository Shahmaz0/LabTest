//
//  SupabaseManager.swift
//  LabTest
//
//  Created by $HahMa on 03/07/25.
//

import Foundation
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: AppConfiguration.Supabase.url)!,
            supabaseKey: AppConfiguration.Supabase.key
        )
    }
}
