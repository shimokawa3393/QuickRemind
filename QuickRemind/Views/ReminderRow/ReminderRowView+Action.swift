import SwiftUI

extension ReminderRowView {
    // MARK: - リマインダーの通知を登録する
    func registerAndClose(_ reminder: Reminder) {
        // 1) 丸め（共通ルールに揃える）
        reminder.date = roundedDate(date: reminder.date)
        
        // 2) 通知登録（過去=即発火／未来=通常）
        let isPastOrNow = reminder.date <= Date()
        NotificationService.register(reminder)
        
        // 3) 任意：即発火したことをUIで知らせたいならアラートを使う
        if isPastOrNow {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showAlert = true }
        }
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
