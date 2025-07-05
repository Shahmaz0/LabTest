//
//  Date+Extensions.swift
//  LabTestResults
//
//  Created by $HahMa on 03/07/25.
//

import Foundation

extension Date {
    func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }
}
