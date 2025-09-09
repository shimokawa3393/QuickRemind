import SwiftUI

extension ReminderRowView {
    // MARK: - リマインダーの通知を登録する
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


    // MARK: - 保存先の強制補正
    func normalizeDestination() {
        // 権限オフ → appOnly 強制
        if !canShowDestinationPicker {
            if reminder.saveDestination != .appOnly { reminder.saveDestination = .appOnly }
            return
        }
        // Reminders 不可なら Reminders を弾く
        if reminder.saveDestination == .reminders && !canUseReminders {
            reminder.saveDestination = canUseCalendar ? .calendar : .appOnly
        }
        // Calendar 不可なら Calendar を弾く
        if reminder.saveDestination == .calendar && !canUseCalendar {
            reminder.saveDestination = canUseReminders ? .reminders : .appOnly
        }
    }
}