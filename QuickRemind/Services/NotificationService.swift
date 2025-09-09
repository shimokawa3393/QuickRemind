import UserNotifications

// MARK: - 通知を登録する
struct NotificationService {
    static func register(_ reminder: Reminder) {
        let content = UNMutableNotificationContent()
        content.title = reminder.title.isEmpty ? "（タイトル未入力）" : reminder.title
        content.body = reminder.date.formatted(.dateTime.hour().minute())
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
        
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
        center.add(request)
    }
    
    static func cancel(_ id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }
}
