//
//  ContentView.swift
//  QuickRemind
//
//  Created by Shouhei Shimokawa on 2025/08/03.
//

import SwiftUI // ビューを作成するために必要
import UserNotifications // 通知を送信するために必要


// MARK: - メイン画面
struct ContentView: View {
    @State private var reminders: [Reminder] = [] // リマインダーを管理する
    @State private var editingReminder: Reminder? = nil // 編集中のリマインダーを管理する
    @State private var showAlert: Bool = false // アラートを表示するためのフラグ
    @State private var showPermissionAlert: Bool = false // 通知の許可を表示するためのフラグ
    @State private var selectedCategory: String = "すべて" // 選択されたカテゴリを管理する
    @State private var categories: [String] = [] // カテゴリを管理する
    @State private var showCategoryManager: Bool = false // カテゴリ管理画面を表示するためのフラグ
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                categoryScrollBar()
                reminderList()
            }
            .sheet(isPresented: $showCategoryManager) {
                CategoryManagerView(reminders: $reminders, categories: $categories)
            }
            .navigationBarItems(trailing: actionButtons())
        }
        .alert(isPresented: $showPermissionAlert) { permissionAlert() }
        .onAppear {
            loadReminders()
            loadCategories()
            NotificationPermissionManager.checkPermission { granted in
                if !granted {
                    showPermissionAlert = true
                }
            }
        }
        .onChange(of: categories) { _ in
            saveCategories()
        }
    }
    
    
    // MARK: - アクションボタンを表示する
    private func actionButtons() -> some View {
        HStack {
            Button(action: {
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
                
                let selected = selectedCategory == "すべて" ? (categories.first ?? "カテゴリーなし") : selectedCategory
                let newReminder = Reminder(id: UUID(), title: "", date: Date().addingTimeInterval(60), category: selected)
                reminders.append(newReminder)
                editingReminder = newReminder
            }) {
                Image(systemName: "plus")
            }
            Button(action: { showCategoryManager = true }) {
                Image(systemName: "gearshape")
            }
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
                            .background(selectedCategory == cat ? Color.blue : Color.gray.opacity(0.4))
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
                )
                .id(reminder.id)
                .listRowSeparator(.hidden)
            }
            .onDelete(perform: deleteReminder)
        }
        .listStyle(PlainListStyle())
    }
    
    
    // MARK: - リマインダーを登録する
    private func tryRegister(_ reminder: Reminder) {
        if reminder.date <= Date() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showAlert = true
            }
            return
        }
        
        NotificationManager.register(reminder)
        
        saveReminders()
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
    
    
    // MARK: - カテゴリを保存する
    private func saveCategories() {
        UserDefaults.standard.set(categories, forKey: "categories")
    }
    
    
    // MARK: - カテゴリを読み込む
    private func loadCategories() {
        if let saved = UserDefaults.standard.stringArray(forKey: "categories"), !saved.isEmpty {
            categories = saved
        } else {
            categories = ["カテゴリーなし"]
            saveCategories()
        }
    }
    
    // MARK: - 通知の許可を表示する
    private func permissionAlert() -> Alert {
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

