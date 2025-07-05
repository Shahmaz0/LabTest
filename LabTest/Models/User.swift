//
//  User.swift
//  LabTestResults
//
//  Created by $HahMa on 03/07/25.
//

import Foundation

struct User: Codable {
    let id: UUID
    let email: String
    let name: String?
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case createdAt = "created_at"
    }
}


