import SwiftUI

extension ReminderView {
    
    // MARK: - リマインダーを追加する
    func addReminder() {
        if let current = editingReminder {
            if current.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                current.title = "（タイトルなし）"
            }
            
            // 通知を再登録（同じIDで上書き）
            NotificationService.register(current)
            saveReminders()
            sortReminders()
            editingReminder = nil
        }
        
        let selected = selectedCategory == "すべて"
        ? (categories.first ?? "カテゴリーなし")
        : selectedCategory
        
        let newReminder = Reminder(
            id: UUID(),
            title: "",
            date: Date().addingTimeInterval(60),
            category: selected
        )
        
        reminders.append(newReminder)
        editingReminder = newReminder // ← これがトリガーになってスクロール＆フォーカスが走る
    }
    
    
    // MARK: - リマインダーを登録する
    func tryRegister(_ reminder: Reminder) {
        if reminder.date <= Date() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showAlert = true
            }
            return
        }
        
        var saveReminder = reminder
        if saveReminder.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            saveReminder.title = "（タイトルなし）"
        }
        
        NotificationService.register(saveReminder)
        if isCalendarAuthorized {
            CalendarService.upsertCalendarEvent(reminder: saveReminder, reminders: &reminders)
        }
        if isReminderAuthorized {
            ReminderService.upsertReminder(reminder: saveReminder, reminders: &reminders)
        }
        
        saveReminders()
        sortReminders()
        reminders = reminders.map { $0 }
    }
    
    
    // MARK: - リマインダーを日付順にする
    func filteredReminders() -> [Reminder] {
        reminders
            .filter { selectedCategory == "すべて" || $0.category == selectedCategory }
            .sorted { $0.date < $1.date }
    }
    
    
    // MARK: - リマインダーを日付順にする
    func sortReminders() {
        reminders.sort { $0.date < $1.date }
    }
    
    
    // MARK: - リマインダーを削除する
    func deleteReminder(at offsets: IndexSet) {
        let filtered = filteredReminders()
        let toDelete: [UUID] = offsets.compactMap { idx in
            guard idx < filtered.count else { return nil }
            return filtered[idx].id
        }
        
        // 先に該当Reminderを捕まえてカレンダー削除
        reminders.filter { toDelete.contains($0.id) }.forEach { savedReminder in
            CalendarService.deleteCalendarEvent(reminder: savedReminder)
            ReminderService.deleteReminder(reminder: savedReminder)
        }
        
        // 本体から削除
        reminders.removeAll { reminder in
            toDelete.contains(reminder.id)
        }
        
        // 編集中だったら解除
        if let current = editingReminder, toDelete.contains(current.id) {
            editingReminder = nil
        }
        
        // 通知キャンセル
        toDelete.forEach { NotificationService.cancel($0) }
        
        saveReminders()
        sortReminders()
    }
    
    
    // MARK: - リマインダーを保存する
    func saveReminders() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(reminders.map { ReminderData(from: $0) }) {
            UserDefaults.standard.set(encoded, forKey: "reminders")
        }
    }
    
    
    // MARK: - リマインダーを読み込む
    func loadReminders() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "reminders"),
           let decoded = try? decoder.decode([ReminderData].self, from: data) {
            reminders = decoded.map { $0.toReminder() }
            sortReminders()
        }
    }
}
