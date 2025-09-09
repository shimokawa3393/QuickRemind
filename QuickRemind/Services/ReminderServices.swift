import EventKit

enum ReminderService {
    private static let selectedReminderListKey = "qr_selectedReminderListID"
    
    static var selectedReminderListIDInDefaults: String? {
        get { UserDefaults.standard.string(forKey: selectedReminderListKey) }
        set { UserDefaults.standard.set(newValue, forKey: selectedReminderListKey) }
    }
    
    // MARK: - リマインダーに追加・更新する
    static func upsertReminder(reminder: Reminder, reminders: inout [Reminder]) {                
        let access = EKAccess.accessLevel(for: .reminder) // ← ここでアクセス状態を正規化
        guard access != .none else {
            print("❌ Reminders 権限なし")
            return
        }
        
        let store = EKEventStore()
        
        // 既存取得（※ここは “EKReminderのitemID” を使う）  
        var ekReminder: EKReminder? = nil
        if let itemID = reminder.ekItemID,  // ← Reminderモデルに追加（String?）
           let item = store.calendarItem(withIdentifier: itemID) as? EKReminder {
            ekReminder = item
        }
        
        // 新規なら作成＆保存先を決定
        if ekReminder == nil {
            let newR = EKReminder(eventStore: store)
            // 保存先の解決（writeOnlyはdefault固定）
            let target: EKCalendar? = {
                switch access {
                case .writeOnly:
                    return store.defaultCalendarForNewReminders()
                case .full:
                    let selectedID = selectedReminderListIDInDefaults
                    if let cal  = resolveTargetList(from: store, selectedReminderListID: selectedID) {
                        return cal
                    }
                    if let defaultCal = store.defaultCalendarForNewReminders(), defaultCal.allowsContentModifications { return defaultCal }
                    return store.calendars(for: .reminder).first(where: { $0.allowsContentModifications })
                case .none:
                    return nil
                }
                
            }()
            guard let target else {
                print("❌ 保存先リストが見つからない")
                return
            }
            newR.calendar = target
            ekReminder = newR
        } else if EKAccess.accessLevel(for: .reminder) == .full {
            // 既存でもフルアクセス時はユーザー選択に追従して移動（任意）
            if let selectedID = selectedReminderListIDInDefaults,
               let target = resolveTargetList(from: store, selectedReminderListID: selectedID),
               ekReminder!.calendar.calendarIdentifier != target.calendarIdentifier {
                ekReminder!.calendar = target
            }
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
        let access = EKAccess.accessLevel(for: .reminder)
        guard access != .none, let itemID = reminder.ekItemID else { return } // ← “項目ID” で探す
        
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
        let access = EKAccess.accessLevel(for: .reminder)
        // 権限なしは弾く
        guard access == .full else {
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
        if let defaultCal = store.defaultCalendarForNewReminders(), defaultCal.allowsContentModifications { return defaultCal }
        return store.calendars(for: .reminder).first(where: { $0.allowsContentModifications })
    }
}
