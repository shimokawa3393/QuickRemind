import Foundation
import SwiftUI // @PublishedやObservableObjectを使うために必要

// MARK: - Reminderモデル
class Reminder: Identifiable, ObservableObject, Equatable{ // Identifiable: 識別子を持つことができるようにする、ObservableObject: オブジェクトの変更を監視することができるようにする、Equatable: 等価性を比較することができるようにする
    static func == (lhs: Reminder, rhs: Reminder) -> Bool { // 等価性を比較する
        return lhs.id == rhs.id // 識別子を比較する
               
    }   
    let id: UUID // 識別子を生成する
    @Published var title: String
    @Published var date: Date
    @Published var category: String
    
    // Reminders.app 用
    @Published var ekItemID: String?        // EKReminder.itemID
    @Published var eventReminderID: String?      // 保存先リスト(EKCalendar.reminder).id
    
    // Calendar.app 用
    @Published var ekEventID: String?       // EKEvent.eventIdentifier
    @Published var eventCalendarID: String? // 保存先(EKCalendar.event).id
    
    
    init(id: UUID, 
         title: String, 
         date: Date, 
         category: String, 
         ekItemID: String? = nil,
         eventReminderID: String? = nil, 
         ekEventID: String? = nil,
         eventCalendarID: String? = nil
         
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.category = category
        self.ekItemID = ekItemID
        self.eventReminderID = eventReminderID
        self.ekEventID = ekEventID
        self.eventCalendarID = eventCalendarID
    }
    
}


// 保存用にObservableObjectを排除したシンプルな構造体
struct ReminderData: Codable {
    let id: UUID
    var title: String
    var date: Date
    var category: String
    var ekItemID: String?
    var eventReminderID: String?
    var ekEventID: String?
    var eventCalendarID: String?
    
    func toReminder() -> Reminder {
        Reminder(id: id, 
                 title: title, 
                 date: date, 
                 category: category, 
                 ekItemID: ekItemID,
                 eventReminderID: eventReminderID, 
                 ekEventID: ekEventID,
                 eventCalendarID: eventCalendarID)
    }
    
    init(from reminder: Reminder) {
        self.id = reminder.id
        self.title = reminder.title
        self.date = reminder.date
        self.category = reminder.category
        self.ekItemID = reminder.ekItemID
        self.eventReminderID = reminder.eventReminderID
        self.ekEventID = reminder.ekEventID
        self.eventCalendarID = reminder.eventCalendarID
    }
}
