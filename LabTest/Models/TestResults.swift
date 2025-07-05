
//
//  TestResults.swift
//  LabTestResults
//
//  Created by $HahMa on 03/07/25.
//
import Foundation

struct TestResult: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let testName: String
    let result: String
    let date: Date
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case testName = "test_name"
        case result
        case date
        case notes
    }
}
