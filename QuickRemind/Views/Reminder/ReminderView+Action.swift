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
        
        let now = Date()
        let initialDate = roundedDate(date: now.addingTimeInterval(60)) // “今”が59秒台でも次のスロットに吸着
        let newReminder = Reminder(
            id: UUID(),
            title: "",
            date: initialDate,
            category: selected
        )
        
        reminders.insert(newReminder, at: 0)
        editingReminder = newReminder // ← これがトリガーになってスクロール＆フォーカスが走る
    }
    
    
    // MARK: - 丸めてから登録する（UIだけに頼らない二重防御）
    func registerWithRoundedDate(_ reminder: Reminder) {
        var rounded = reminder
        // ここで remindAt 的な日時プロパティ名に合わせて置き換える
        // 例: rounded.triggerDate = roundedDate(reminder.triggerDate)
        //     rounded.fireDate    = roundedDate(reminder.fireDate)
        // モデルの日時プロパティ名に1行で合わせる
        rounded.date = roundedDate(date: reminder.date)
        
        tryRegister(rounded: rounded)   // 既存の登録処理を呼ぶ
    }
    
    
    // MARK: - リマインダーを登録する
    func tryRegister(rounded: Reminder) {
        if rounded.date <= Date() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showAlert = true
            }
            return
        }
        
        var saveReminder = rounded
        if saveReminder.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            saveReminder.title = "（タイトルなし）"
        }
        
        NotificationService.register(saveReminder)
        
        switch saveReminder.saveDestination {
        case .appOnly:
            // アプリ内DBへ保存（お前の既存実装）
            break
        case .reminders:
            ReminderService.upsertReminder(reminder: rounded, reminders: &reminders)
        case .calendar:
            CalendarService.upsertCalendarEvent(reminder: rounded, reminders: &reminders)
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
