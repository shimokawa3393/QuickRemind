import SwiftUI


enum DateFormat {   
    // MARK: - 日時をフォーマットする
    static func formattedDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "yyyy / M / d (E) HH:mm"
            return formatter.string(from: date)
        }
}