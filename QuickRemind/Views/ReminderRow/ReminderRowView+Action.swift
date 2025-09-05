import SwiftUI

extension ReminderRowView {
    // MARK: - リマインダーを登録する
    func registerAndClose(_ reminder: Reminder) {
        if reminder.date < Date() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showAlert = true
            }
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = reminder.title.isEmpty ? "（タイトル未入力）" : reminder.title
        content.body = reminder.date.formatted(.dateTime.hour().minute())
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminder.date
        )
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
        UNUserNotificationCenter.current().add(request)
        
        onRegister()
        editingReminder = nil
    }
}