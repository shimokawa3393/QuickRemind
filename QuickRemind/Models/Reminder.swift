import Foundation
import SwiftUI // @PublishedやObservableObjectを使うために必要

// MARK: - Reminderモデル
class Reminder: Identifiable, ObservableObject, Equatable{ // Identifiable: 識別子を持つことができるようにする、ObservableObject: オブジェクトの変更を監視することができるようにする、Equatable: 等価性を比較することができるようにする
    static func == (lhs: Reminder, rhs: Reminder) -> Bool { // 等価性を比較する
        return lhs.id == rhs.id && // 識別子を比較する
        lhs.title == rhs.title && // タイトルを比較する
        lhs.date == rhs.date && // 日時を比較する
        lhs.category == rhs.category // カテゴリを比較する
    }
    
    let id: UUID // 識別子を生成する
    @Published var title: String
    @Published var date: Date
    @Published var category: String
    @Published var calendarID: String?
    
    init(id: UUID, title: String, date: Date, category: String, calendarID: String? = nil) {
        self.id = id
        self.title = title
        self.date = date
        self.category = category
        self.calendarID = calendarID
    }
}

// 保存用にObservableObjectを排除したシンプルな構造体
struct ReminderData: Codable {
    let id: UUID 
    var title: String
    var date: Date
    var category: String
    var calendarID: String?

    
    func toReminder() -> Reminder {
        Reminder(id: id, title: title, date: date, category: category, calendarID: calendarID)
    }
    
    init(from reminder: Reminder) {
        self.id = reminder.id
        self.title = reminder.title
        self.date = reminder.date
        self.category = reminder.category
        self.calendarID = reminder.calendarID
    }
}