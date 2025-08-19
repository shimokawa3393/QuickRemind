//
//  QuickRemindTests.swift
//  QuickRemindTests
//
//  Created by Shouhei Shimokawa on 2025/08/03.
//

import Testing
import Foundation
@testable import QuickRemind

struct QuickRemindTests {
    @Test func filteredRemindersFiltersByCategoryAndSorts() {
        var view = ContentView()
        
        @Test func example() async throws {
            // Write your test here and use APIs like `#expect(...)` to check expected conditions.
            let date1 = Date(timeIntervalSince1970: 1_000)
            let date2 = Date(timeIntervalSince1970: 2_000)
            let date3 = Date(timeIntervalSince1970: 3_000)
            
            view.reminders = [
                Reminder(id: UUID(), title: "A", date: date3, category: "Work"),
                Reminder(id: UUID(), title: "B", date: date1, category: "Home"),
                Reminder(id: UUID(), title: "C", date: date2, category: "Work"),
            ]
            
            view.selectedCategory = "Work"
            let result = view.filteredReminders()
            
            #expect(result.count == 2)
            #expect(result[0].date == date2)
            #expect(result[1].date == date3)
        }
        
        @Test func sortRemindersOrdersByDateAscending() {
            var view = ContentView()
            
            let date1 = Date(timeIntervalSince1970: 3_000)
            let date2 = Date(timeIntervalSince1970: 1_000)
            let date3 = Date(timeIntervalSince1970: 2_000)
            
            view.reminders = [
                Reminder(id: UUID(), title: "A", date: date1, category: "Work"),
                Reminder(id: UUID(), title: "B", date: date2, category: "Work"),
                Reminder(id: UUID(), title: "C", date: date3, category: "Work"),
            ]
            
            view.sortReminders()
            
            let dates = view.reminders.map { $0.date }
            #expect(dates == [date2, date3, date1])
        }
    }
    
