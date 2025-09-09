import EventKit

enum CalendarService {
    private static let selectedCalendarKey = "qr_selectedCalendarID"
    
    static var selectedCalendarIDInDefaults: String? {
        get { UserDefaults.standard.string(forKey: selectedCalendarKey) }
        set { UserDefaults.standard.set(newValue, forKey: selectedCalendarKey) }
    }
    
    // MARK: - カレンダーに追加・更新する
    static func upsertCalendarEvent(reminder: Reminder, reminders: inout [Reminder]) {
        let access = EKAccess.accessLevel(for: .event)
        guard access != .none else {
            print("❌ Calendar 権限なし")
            return
        }
        
        let store = EKEventStore()
        
        // 既存イベントがあれば取得
        var event: EKEvent? = nil
        if let id = reminder.ekEventID {
            event = store.event(withIdentifier: id)
        }
        
        // 無ければ新規
        if event == nil {
            let newEvent = EKEvent(eventStore: store)
            let target: EKCalendar? = {
                switch access {
                case .writeOnly:
                    // 読めないので default 固定
                    return store.defaultCalendarForNewEvents
                case .full:
                    if let selectedID = selectedCalendarIDInDefaults,
                       let cal = resolveTargetCalendar(from: store, selectedCalendarID: selectedID) {
                        return cal
                    }
                    if let def = store.defaultCalendarForNewEvents, def.allowsContentModifications { return def }
                    return store.calendars(for: .event).first(where: { $0.allowsContentModifications })
                case .none:
                    return nil
                }
            }()
            guard let target else { print("❌ 保存先カレンダーなし"); return }
            newEvent.calendar = target
            event = newEvent
        } else if access == .full {
            // 既存イベントでもユーザー選択に追従（任意）
            if let selectedID = selectedCalendarIDInDefaults,
               let target = resolveTargetCalendar(from: store, selectedCalendarID: selectedID),
               event!.calendar.calendarIdentifier != target.calendarIdentifier {
                event!.calendar = target
            }
        }
        
        guard let event = event else {
            print("❌ EKEvent 初期化失敗（defaultCalendar=nil の可能性）")
            return
        }
        
        // イベント作成
        event.title = reminder.title
        event.startDate = reminder.date
        event.endDate = reminder.date.addingTimeInterval(60 * 60) // デフォ60分
        event.notes = "カテゴリー：" + reminder.category
        
        // 🔔 通知（既存アラームをクリアしてから付け直す）
        event.alarms = []  // ← 重要：編集のたびに積み上がるのを防止
        event.addAlarm(EKAlarm(absoluteDate: reminder.date)) // 定刻に通知
        
        do {
            try store.save(event, span: .thisEvent)
            if let idx = reminders.firstIndex(where: { $0.id == reminder.id }) {
                reminders[idx].ekEventID = event.eventIdentifier
                reminders[idx].eventCalendarID = event.calendar.calendarIdentifier
            }
            print("✅ カレンダーにイベントを保存しました")
        } catch {
            print("❌ カレンダー保存失敗: \(error.localizedDescription)")
        }
    }
    
    
    // MARK: - カレンダーから削除する
    static func deleteCalendarEvent(reminder: Reminder) {
        let access = EKAccess.accessLevel(for: .event)
        guard access != .none, let id = reminder.ekEventID else { return }
        
        let store = EKEventStore()
        if let e = store.event(withIdentifier: id) {
            do {
                try store.remove(e, span: .thisEvent, commit: true)
                print("✅ カレンダーイベント削除（id: \(id)）")
            } catch {
                print("❌ カレンダー削除失敗: \(error.localizedDescription)")
            }
        }
    }
    
    
    // MARK: - 保有しているカレンダーアプリを読み込む（アクセス権限付与後に実行）
    static func loadEventCalendars(selectedCalendarID: String?) -> (calendars: [EKCalendar], selectedCalendarID: String?) {
        let store = EKEventStore()
        let access = EKAccess.accessLevel(for: .event)
        // 権限なしは弾く
        guard access == .full else {
            return ([], nil)
        }
        let all = store.calendars(for: .event).filter { $0.allowsContentModifications }
        
        // 以前の選択が消えてたらリセット
        var newId = selectedCalendarID
        if let id = newId, all.first(where: { $0.calendarIdentifier == id }) == nil {
            newId = nil
            UserDefaults.standard.removeObject(forKey: selectedCalendarKey)
        }
        return (all, newId)
    }
    
    
    // MARK: - 保存先カレンダーを解決する
    static func resolveTargetCalendar(from store: EKEventStore, selectedCalendarID: String?) -> EKCalendar? {
        if let id = selectedCalendarID,
           let cal = store.calendar(withIdentifier: id),
           cal.allowsContentModifications {
            return cal
        }
        // フォールバック：デフォ or 編集可能な先頭
        if let def = store.defaultCalendarForNewEvents, def.allowsContentModifications { return def }
        return store.calendars(for: .event).first(where: { $0.allowsContentModifications })
    }
}
