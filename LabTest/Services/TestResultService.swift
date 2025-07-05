//
//  LabTestResults
//
//  Created by $HahMa on 03/07/25.
//

import Supabase
import Foundation

protocol TestResultServiceProtocol {
    func fetchTestResults(userId: UUID) async throws -> [TestResult]
    func addTestResult(testResult: TestResult) async throws
    func deleteTestResult(id: UUID) async throws
}

class TestResultService: TestResultServiceProtocol {
    private let client = SupabaseManager.shared.client
    
    func fetchTestResults(userId: UUID) async throws -> [TestResult] {
        let query = try await client
            .from("test_results")
            .select()
            .eq("user_id", value: userId)
            .order("date", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([TestResult].self, from: query.data)
    }
    
    func addTestResult(testResult: TestResult) async throws {
        try await client
            .from("test_results")
            .insert(testResult)
            .execute()
    }
    
    func deleteTestResult(id: UUID) async throws {
        try await client
            .from("test_results")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}
