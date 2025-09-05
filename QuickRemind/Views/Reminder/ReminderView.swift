//
//  ReminderView.swift
//  QuickRemind
//
//  Created by Shouhei Shimokawa on 2025/08/03.
//

import UIKit
import SwiftUI // ビューを作成するために必要
import UserNotifications // 通知を送信するために必要
import EventKit // カレンダーと連携するために必要


// MARK: - メイン画面
struct ReminderView: View {
    // MARK: - リマインダー & カテゴリ関連
    @State var reminders: [Reminder] = []                  // リマインダーの配列
    @State var editingReminder: Reminder? = nil            // 編集中のリマインダー
    @State var categories: [String] = []                   // カテゴリの配列
    @State var selectedCategory: String = "すべて"          // 選択されたカテゴリ
    
    // MARK: - UI表示制御
    @State var showAlert: Bool = false                     // アラートを表示する
    @State private var showNotificationAlert: Bool = false         // 通知の許可を表示する
    @State private var showCategoryManager: Bool = false           // カテゴリ管理画面を表示する
    @State private var showHelp: Bool = false                      // ヘルプを表示する
    
    // MARK: - カレンダー連携
    private let selectedCalendarKey = "qr_selectedCalendarID"      // UserDefaults用キー
    @State var showCalendarAlert: Bool = false             // カレンダー連携のアラートを表示する
    @State var showCalendarOpenSettings: Bool = false              // 設定画面を表示する
    @State var calendarMessage: String = ""                // カレンダー連携のメッセージ
    @State var calendarAuthStatus: EKAuthorizationStatus = .notDetermined // カレンダーの権限を取得する
    @State var isCalendarAuthorized = false                // カレンダーの権限を取得する
    @State var availableCalendars: [EKCalendar] = []       // カレンダー選択用
    @State var selectedCalendarID: String? = UserDefaults.standard.string(forKey: "qr_selectedCalendarID")
    @State var showCalendarPicker: Bool = false            // カレンダー選択用
    
    // MARK: - リマインダー連携
    private let selectedReminderListKey = "qr_selectedReminderListID"       // UserDefaults用キー
    @State var showReminderAlert: Bool = false                      // リマインダー連携のアラートを表示する
    @State var showReminderOpenSettings: Bool = false               // 設定画面を表示する
    @State var reminderMessage: String = ""                         // リマインダー連携のメッセージ
    @State var reminderAuthStatus: EKAuthorizationStatus = .notDetermined // リマインダーの権限を取得する
    @State var isReminderAuthorized = false                         // リマインダーの権限を取得する
    @State var availableReminderLists: [EKCalendar] = []            // リマインダー選択用
    @State var selectedReminderListID: String? = UserDefaults.standard.string(forKey: "qr_selectedReminderListID")
    @State var showReminderPicker: Bool = false                     // リマインダー選択用

    // MARK: - その他
    @FocusState private var focusedID: UUID?                       // フォーカスを設定する
    
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                categoryScrollBar()
                Spacer()
                HStack {
                    Spacer()
                    Button(action: addReminder) {
                        Label(title: { Text("新規") }, icon: { Image(systemName: "plus.circle.fill") })
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
                CategoryView(reminders: $reminders, categories: $categories)
            }
            .sheet(isPresented: $showCalendarPicker) {
                CalendarPickerView(
                    calendars: availableCalendars,
                    selectedCalendarID: $selectedCalendarID
                ) {
                    showCalendarPicker = false
                }
            }
            .sheet(isPresented: $showReminderPicker) {
                ReminderListPickerView(
                    lists: availableReminderLists,
                    selectedReminderListID: $selectedReminderListID
                ) {
                    showReminderPicker = false
                }
            }
            .navigationBarItems(trailing: actionButtons())
        }
        .alert(isPresented: $showNotificationAlert) { notificationPermissionAlert() }
        .onAppear {
            loadReminders()
            categories = CategoryService.loadCategories()
            NotificationPermissionManager.checkPermission { granted in
                if !granted {
                    showNotificationAlert = true
                }
            }
            // カレンダーの権限を取得
            let calendarStatus = EKEventStore.authorizationStatus(for: .event)
            calendarAuthStatus = calendarStatus
            isCalendarAuthorized = (calendarStatus == .authorized)

            // リマインダーの権限を取得
            let reminderStatus = EKEventStore.authorizationStatus(for: .reminder)
            reminderAuthStatus = reminderStatus
            isReminderAuthorized = (reminderStatus == .authorized)
            
            // 既に許可済みなら、それぞれの一覧を先読み（UX向上）
            if isCalendarAuthorized {
                let result = CalendarService.loadEventCalendars(selectedCalendarID: selectedCalendarID)
                availableCalendars = result.calendars
                selectedCalendarID = result.selectedCalendarID
            }
            if isReminderAuthorized {
                let result = ReminderService.loadReminderLists(selectedReminderListID: selectedReminderListID)
                availableReminderLists = result.reminderLists
                selectedReminderListID = result.selectedReminderListID
            }

            
        }
        .onChange(of: categories) { _ in
            CategoryService.saveCategories(categories: categories)
        }
    }
    
    
    // MARK: - アクションボタンを表示する
    private func actionButtons() -> some View {
        HStack {
            Button(action: { showCategoryManager = true }) {
                Image(systemName: "tag")
            }
            Menu {
                Button(action: AppReview.rateApp) {
                    Label(title: { Text("アプリを評価する") }, icon: { Image(systemName: "star.fill") })
                }
                Button(action: linkCalendars) {
                    Label(title: { Text("カレンダーと連携する") }, icon: { Image(systemName: "calendar") })
                }
                Button(action: linkReminders) {
                    Label(title: { Text("リマインダーと連携する") }, icon: { Image(systemName: "checklist.checked") })
                }
                Button(action: { showHelp = true }) {
                    Label(title: { Text("QuickRemindの操作方法") }, icon: { Image(systemName: "questionmark.circle") })
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        
        .alert("カレンダー連携", isPresented: $showCalendarAlert) {
            Button("カレンダーを選ぶ") {
                let result = CalendarService.loadEventCalendars(selectedCalendarID: selectedCalendarID)
                availableCalendars = result.calendars
                selectedCalendarID = result.selectedCalendarID
                showCalendarPicker = true
            }
            if showCalendarOpenSettings {
                Button("設定を開く") { AppSettings.open() }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text(calendarMessage)
        }

        .alert("リマインダー連携", isPresented: $showReminderAlert) {
            Button("リマインダーを選ぶ") {
                let result = ReminderService.loadReminderLists(selectedReminderListID: selectedReminderListID)
                availableReminderLists = result.reminderLists
                selectedReminderListID = result.selectedReminderListID
                showReminderPicker = true
            }
            if showReminderOpenSettings {
                Button("設定を開く") { AppSettings.open() }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text(reminderMessage)
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
}

// MARK: - プレビュー
#Preview {
    ReminderView()
}

