//
//  HomeworkManager.swift
//  bettermathflat
//
//  Created by youngzheimer on 2/24/25.
//

import Foundation

func getDate(days: Int, dateFormat: String? = "yyyy-MM-dd") -> String {
    let today = Date()
    
    guard let targetday = Calendar.current.date(byAdding: .day, value: days, to: today) else {
        return ""
    }
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = dateFormat

    let targetdayString = dateFormatter.string(from: targetday)
    
    return targetdayString
}
