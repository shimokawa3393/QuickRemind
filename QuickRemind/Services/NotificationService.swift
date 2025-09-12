import UserNotifications

// MARK: - 通知を登録する
struct NotificationService {
    static func register(_ reminder: Reminder) {
        let content = UNMutableNotificationContent()
        content.title = reminder.title.isEmpty ? "（タイトル未入力）" : reminder.title
        content.body = reminder.date.formatted(.dateTime.hour().minute())
        content.sound = .default

        let now = Date()
        if reminder.date <= now {
            // --- 即発火（過去日時や現在時刻） ---
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: reminder.id.uuidString,
                content: content,
                trigger: trigger
            )
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
            center.add(request)

        } else {
            // --- 通常スケジュール（未来日時） ---
            let triggerDate = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: reminder.date
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let request = UNNotificationRequest(
                identifier: reminder.id.uuidString,
                content: content,
                trigger: trigger
            )
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
            center.add(request)
        }
    }
    
    static func cancel(_ id: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }
}
