//
//  ContentView.swift
//  QuickRemind
//
//  Created by Shouhei Shimokawa on 2025/08/03.
//

import UIKit
import SwiftUI // ビューを作成するために必要
import UserNotifications // 通知を送信するために必要
import EventKit // カレンダーと連携するために必要


// MARK: - メイン画面
struct ContentView: View {
    @State private var reminders: [Reminder] = [] // リマインダーの配列
    @State private var editingReminder: Reminder? = nil // 編集中のリマインダー
    @State private var showAlert: Bool = false // アラートを表示する
    @State private var showNotificationAlert: Bool = false // 通知の許可を表示する
    @State private var selectedCategory: String = "すべて" // 選択されたカテゴリ
    @State private var categories: [String] = [] // カテゴリの配列
    @State private var showCategoryManager: Bool = false // カテゴリ管理画面を表示する
    @State private var showHelp: Bool = false // ヘルプを表示する
    @State private var showCalendarAlert: Bool = false // カレンダー連携のアラートを表示する
    @State private var showOpenSettings: Bool = false // 設定画面を表示する
    @State private var calendarMessage: String = "" // カレンダー連携のメッセージ
    @State private var calendarAuthStatus: EKAuthorizationStatus = .notDetermined // カレンダーの権限を取得する
    @State private var isCalendarAuthorized = false // カレンダーの権限を取得する
    @State private var availableCalendars: [EKCalendar] = [] // カレンダー選択用
    @State private var selectedCalendarID: String? = UserDefaults.standard.string(forKey: "qr_selectedCalendarID") 
    @State private var showCalendarPicker: Bool = false // カレンダー選択用
    @FocusState private var focusedID: UUID? // フォーカスを設定する
    
    private let selectedCalendarKey = "qr_selectedCalendarID" // カレンダー選択用
    
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                categoryScrollBar()
                Spacer()
                HStack {
                    Spacer()
                    Button(action: addReminder) {
                        Label(title: { Text("追加") }, icon: { Image(systemName: "plus.circle.fill") })
                            .font(.title2)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                ZStack {
                                    Capsule()
                                        .fill(Color.accentColor.opacity(0.2)) // ← 背景
                                    Capsule()
                                        .stroke(Color.accentColor, lineWidth: 1) // ← 枠線
                                }
                            )
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 12)
                }
                Spacer()
                reminderList()
            }
            .sheet(isPresented: $showCategoryManager) {
                CategoryManagerView(reminders: $reminders, categories: $categories)
            }
            .sheet(isPresented: $showCalendarPicker) {
                CalendarPickerView(
                    calendars: availableCalendars,
                    selectedCalendarID: $selectedCalendarID
                ) {
                    showCalendarPicker = false
                }
            }
            .navigationBarItems(trailing: actionButtons())
        }
        .alert(isPresented: $showNotificationAlert) { notificationPermissionAlert() }
        .onAppear {
            loadReminders()
            loadCategories()
            NotificationPermissionManager.checkPermission { granted in
                if !granted {
                    showNotificationAlert = true
                }
            }
            // カレンダーの権限を取得
            let status = EKEventStore.authorizationStatus(for: .event)
            calendarAuthStatus = status
            isCalendarAuthorized = (status == .authorized)
            
            // 既に許可済みなら一覧を先読み（UX向上）
            if isCalendarAuthorized {
                loadEventCalendars()
            }
        }
        .onChange(of: categories) { _ in
            saveCategories()
        }
    }
    
    
    // MARK: - アクションボタンを表示する
    private func actionButtons() -> some View {
        HStack {
            Button(action: { showCategoryManager = true }) {
                Image(systemName: "tag")
            } 
            Menu {
                Button(action: rateApp) {
                    Label(title: { Text("アプリを評価する") }, icon: { Image(systemName: "star.fill") })
                }
                Button(action: linkCalendar) {
                    Label(title: { Text("カレンダーと連携する") }, icon: { Image(systemName: "calendar.badge.exclamationmark") })
                }
                Button(action: { showHelp = true }) {
                    Label(title: { Text("リマインダーの操作方法") }, icon: { Image(systemName: "questionmark.circle") })
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        
        .alert("カレンダー連携", isPresented: $showCalendarAlert) {
            if showOpenSettings {
                Button("設定を開く") { AppSettings.open() }
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text(calendarMessage)
        }
        
        .alert("操作のヒント", isPresented: $showHelp) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("編集ON/OFF：リマインダー枠内をタップ\nリマインダーの削除：左にスワイプ")
        }
    }
    
    
    // MARK: - カテゴリスクロールバーを表示する
    private func categoryScrollBar() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(["すべて"] + categories, id: \.self) { cat in
                    Button(action: { selectedCategory = cat }) {
                        Text(cat)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedCategory == cat ? Color.accentColor : Color.gray.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    
    // MARK: - リマインダーリストを表示する
    private func reminderList() -> some View {
        ScrollViewReader { proxy in
            List {
                ForEach(filteredReminders()) { reminder in
                    ReminderRowView(
                        reminder: reminder,
                        editingReminder: $editingReminder,
                        showAlert: $showAlert,
                        onRegister: {
                            tryRegister(reminder)
                            sortReminders()
                        },
                        categories: categories,
                        focused: $focusedID
                    )
                    .id(reminder.id)
                    .listRowSeparator(.hidden)
                }
                .onDelete(perform: deleteReminder)
            }
            .listStyle(.plain)
            .onChange(of: editingReminder?.id) { id in
                guard let id else { return }
                // 描画完了後にスクロール
                DispatchQueue.main.async {
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(id, anchor: UnitPoint.center) // ★ UnitPointを明示
                    }
                    focusedID = id
                }
            }
        }
    }
    
    
    // MARK: - リマインダーを追加する
    private func addReminder() {
        if let current = editingReminder {
            if current.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                current.title = "（タイトルなし）"
            }
            
            // 通知を再登録（同じIDで上書き）
            NotificationManager.register(current)
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
    private func tryRegister(_ reminder: Reminder) {
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
        
        NotificationManager.register(saveReminder)
        if isCalendarAuthorized {
            upsertCalendarEvent(reminder: saveReminder)
        } 
        
        sortReminders()
        reminders = reminders.map { $0 }
    }
    
    
    // MARK: - リマインダーを日付順にする
    private func filteredReminders() -> [Reminder] {
        reminders
            .filter { selectedCategory == "すべて" || $0.category == selectedCategory }
            .sorted { $0.date < $1.date }
    }
    
    
    // MARK: - リマインダーを日付順にする
    private func sortReminders() {
        reminders.sort { $0.date < $1.date }
    }
    
    
    // MARK: - リマインダーを削除する
    private func deleteReminder(at offsets: IndexSet) {
        let filtered = filteredReminders()
        let toDelete: [UUID] = offsets.compactMap { idx in
            guard idx < filtered.count else { return nil }
            return filtered[idx].id
        }
        
        // 先に該当Reminderを捕まえてカレンダー削除
        reminders.filter { toDelete.contains($0.id) }.forEach { savedReminder in
            deleteCalendarEvent(reminder: savedReminder)
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
        toDelete.forEach { NotificationManager.cancel($0) }
        
        saveReminders()
        sortReminders()
    }
    
    
    // MARK: - リマインダーを保存する
    private func saveReminders() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(reminders.map { ReminderData(from: $0) }) {
            UserDefaults.standard.set(encoded, forKey: "reminders")
        }
    }
    
    
    // MARK: - リマインダーを読み込む
    private func loadReminders() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "reminders"),
           let decoded = try? decoder.decode([ReminderData].self, from: data) {
            reminders = decoded.map { $0.toReminder() }
            sortReminders()
        }
    }
    
    
    // MARK: - カテゴリーを保存する
    private func saveCategories() {
        UserDefaults.standard.set(categories, forKey: "categories")
    }
    
    
    // MARK: - カテゴリーを読み込む
    private func loadCategories() {
        if let saved = UserDefaults.standard.stringArray(forKey: "categories"), !saved.isEmpty {
            categories = saved
        } else {
            categories = ["カテゴリーなし"]
            saveCategories()
        }
    }
    
    
    // MARK: - アプリを評価する
    @MainActor
    func rateApp() {
        let appID = "6751082907" // QuickRemind の App Store ID
        // 1) まずは「レビューを書く」直行（最短）
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)?action=write-review"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return
        }
        // 2) 万一失敗時はアプリページへ（ユーザーが自分で★へ移動できる）
        if let fallback = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)") {
            UIApplication.shared.open(fallback, options: [:], completionHandler: nil)
        }
    }
    
    
    // MARK: - カレンダーと連携する
    @MainActor
    private func linkCalendar() {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .notDetermined:
            let store = EKEventStore()
            store.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    self.calendarAuthStatus = EKEventStore.authorizationStatus(for: .event)
                    self.isCalendarAuthorized = granted
                    if granted {
                        loadEventCalendars()
                        showCalendarPicker = true
                        calendarMessage = "カレンダーの利用が許可されました ✅"
                        showOpenSettings = false
                    } else {
                        calendarMessage = "カレンダーの権限が拒否されています。\n設定アプリから変更してください。"
                        showOpenSettings = true
                    }
                    showCalendarAlert = true
                }
            }
            
        case .authorized:
            loadEventCalendars()
            showOpenSettings = false
            showCalendarPicker = true
            
        case .denied, .restricted:
            calendarMessage = "カレンダーの権限がオフです。\n設定アプリで QuickRemind のカレンダーを許可してください。"
            showOpenSettings = true
            showCalendarAlert = true
            
        @unknown default:
            calendarMessage = "権限の状態を判定できませんでした。"
            showOpenSettings = false
            showCalendarAlert = true
        }
    }
    
    
    // MARK: - カレンダーに追加・更新する
    private func upsertCalendarEvent(reminder: Reminder) {
        // 権限チェック
        guard EKEventStore.authorizationStatus(for: .event) == .authorized else {
            return
        }
        
        let store = EKEventStore()
        
        // 既存イベントがあれば取得
        var event: EKEvent? = nil
        if let id = reminder.calendarID {
            event = store.event(withIdentifier: id)
        }
        
        // 無ければ新規
        if event == nil {
            event = EKEvent(eventStore: store)
            guard let target = resolveTargetCalendar(from: store) else {
                print("❌ 保存先カレンダーが見つからない")
                return
            }
            event?.calendar = target
        }
        
        guard let event = event else {
            print("❌ EKEvent 初期化失敗（defaultCalendar=nil の可能性）")
            return
        }
        
        // イベント作成
        event.title = reminder.title
        event.startDate = reminder.date
        event.endDate = reminder.date.addingTimeInterval(60 * 30) // デフォ30分
        event.notes = "カテゴリー：" + reminder.category
        event.calendar = store.defaultCalendarForNewEvents // 既定カレンダーに設定
        
        // 🔔 通知（既存アラームをクリアしてから付け直す）
        event.alarms = []  // ← 重要：編集のたびに積み上がるのを防止
        event.addAlarm(EKAlarm(absoluteDate: reminder.date)) // 定刻に通知
        
        do {
            try store.save(event, span: .thisEvent)
            if let idx = reminders.firstIndex(where: { $0.id == reminder.id }) {
                reminders[idx].calendarID = event.eventIdentifier
                saveReminders()
            }
            print("✅ カレンダーにイベントを保存しました")
        } catch {
            print("❌ カレンダー保存失敗: \(error.localizedDescription)")
        }
    }
    
    
    // MARK: - カレンダーから削除する
    private func deleteCalendarEvent(reminder: Reminder) {
        guard EKEventStore.authorizationStatus(for: .event) == .authorized else { return }
        guard let id = reminder.calendarID else { return }
        
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
    private func loadEventCalendars() {
        let store = EKEventStore()
        // 書き込み不可を弾く（Google共有など読み取り専用が混ざる）
        let all = store.calendars(for: .event).filter { $0.allowsContentModifications }
        availableCalendars = all
        
        // 以前の選択が消えてたらリセット
        if let id = selectedCalendarID, all.first(where: { $0.calendarIdentifier == id }) == nil {
            selectedCalendarID = nil
            UserDefaults.standard.removeObject(forKey: selectedCalendarKey)
        }
    }
    
    
    // MARK: - 保存先カレンダーを解決する
    private func resolveTargetCalendar(from store: EKEventStore) -> EKCalendar? {
        if let id = selectedCalendarID,
           let cal = store.calendar(withIdentifier: id),
           cal.allowsContentModifications {
            return cal
        }
        // フォールバック：デフォ or 編集可能な先頭
        if let def = store.defaultCalendarForNewEvents, def.allowsContentModifications { return def }
        return store.calendars(for: .event).first(where: { $0.allowsContentModifications })
    }
    
    
    
    
    // MARK: - 通知の許可を表示する
    private func notificationPermissionAlert() -> Alert {
        Alert(
            title: Text("通知がオフになっています"),
            message: Text("通知をオンにすると、リマインダーが正常に動作します。\n設定から変更できます。"),
            primaryButton: .default(Text("設定を開く"), action: AppSettings.open),
            secondaryButton: .cancel(Text("今はしない"))
        )
    }
    
}

// MARK: - プレビュー
#Preview {
    ContentView()
}

