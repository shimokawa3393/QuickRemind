import EventKit

enum ReminderService {
    private static let selectedReminderListKey = "selectedReminderListID"
    
    // MARK: - リマインダーに追加・更新する
    static func upsertReminder(reminder: Reminder, reminders: inout [Reminder]) {
        print("🔔 ReminderService.upsertReminder")
        
        let status = EKEventStore.authorizationStatus(for: .reminder)
        // iOS17以降対応：fullAccess / writeOnly を通す
        guard status == .authorized || status == .fullAccess || status == .writeOnly else {
            print("❌ 権限なし: \(status)")
            return
        }
        
        let store = EKEventStore()
        
        // 既存取得（※ここは “EKReminderのitemID” を使う）  
        var ekReminder: EKReminder? = nil
        if let itemID = reminder.ekItemID,  // ← Reminderモデルに追加（String?）
           let item = store.calendarItem(withIdentifier: itemID) as? EKReminder {
            ekReminder = item
        }
        
        // 無ければ新規
        if ekReminder == nil {
            let newR = EKReminder(eventStore: store)
            // 保存先の解決（writeOnlyはdefault固定）
            let target: EKCalendar? = {
                if status == .writeOnly {
                    return store.defaultCalendarForNewReminders()
                }
                // fullAccess/authorized：選択があればそれ、なければdefault
                if let cal = resolveTargetList(from: store, selectedReminderListID: reminder.eventReminderID) {
                    return cal
                }
                return store.defaultCalendarForNewReminders()
            }()
            guard let target else {
                print("❌ 保存先リストが見つからない")
                return
            }
            newR.calendar = target
            ekReminder = newR
        }

        // ここで Optional 解除（以降は非Optionalで扱う）
        guard let ekReminder = ekReminder else {
            print("❌ EKReminder 初期化失敗")
            return
        }
        
        // リマインダー内容を設定
        ekReminder.title = reminder.title.isEmpty ? "（タイトルなし）" : reminder.title
        ekReminder.notes = "カテゴリー：" + reminder.category
        
        // 期限（dueDateComponents）
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.date)
        ekReminder.dueDateComponents = comps
        
        // 🔔 通知（既存アラームをクリアしてから付け直す）
        ekReminder.alarms = []
        ekReminder.addAlarm(EKAlarm(absoluteDate: reminder.date))
        
        do {
            try store.save(ekReminder, commit: true)
            if let idx = reminders.firstIndex(where: { $0.id == reminder.id }) {
                reminders[idx].ekItemID = ekReminder.calendarItemIdentifier
                reminders[idx].eventReminderID = ekReminder.calendar.calendarIdentifier
            }
            print("✅ Appleリマインダーに保存しました")
        } catch {
            print("❌ Appleリマインダー保存失敗: \(error.localizedDescription)")
        }
    }
    
    
    // MARK: - リマインダーから削除する
    static func deleteReminder(reminder: Reminder) {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        guard status == .authorized || status == .fullAccess || status == .writeOnly else { return }
        guard let itemID = reminder.ekItemID else { return } // ← “項目ID” で探す
        
        let store = EKEventStore()
        if let ekReminder = store.calendarItem(withIdentifier: itemID) as? EKReminder {
            do {
                try store.remove(ekReminder, commit: true)
                print("✅ Appleリマインダー削除（id: \(itemID)）")
            } catch {
                print("❌ Appleリマインダー削除失敗: \(error.localizedDescription)")
            }
        }else {
            print("❌ Appleリマインダーが見つからない: \(itemID)")
        }
    }
    
    
    // MARK: - 保有しているリマインダーリストを読み込む
    static func loadReminderLists(selectedReminderListID: String?) -> (reminderLists: [EKCalendar], selectedReminderListID: String?) {
        let store = EKEventStore()
        let status = EKEventStore.authorizationStatus(for: .reminder)
        // writeOnlyは読めない → 空を返す（UIで案内）
        guard status == .authorized || status == .fullAccess else {
            return ([], nil)
        }
        
        // 書き込み不可を弾く（共有など読み取り専用を排除）
        let all = store.calendars(for: .reminder).filter { $0.allowsContentModifications }
        
        // 以前の選択が消えてたらリセット
        var newId = selectedReminderListID
        if let id = newId, all.first(where: { $0.calendarIdentifier == id }) == nil {
            newId = nil
            UserDefaults.standard.removeObject(forKey: selectedReminderListKey)
        }
        return (all, newId)
    }
    
    
    // MARK: - 保存先リストを解決する
    static func resolveTargetList(from store: EKEventStore, selectedReminderListID: String?) -> EKCalendar? {
        if let id = selectedReminderListID,
           let cal = store.calendar(withIdentifier: id),
           cal.allowsContentModifications {
            return cal
        }
        // フォールバック：編集可能な先頭
        return store.calendars(for: .reminder).first(where: { $0.allowsContentModifications })
    }
}
